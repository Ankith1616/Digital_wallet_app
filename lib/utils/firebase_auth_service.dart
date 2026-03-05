import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';
import '../firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current signed-in user (null if not logged in)
  User? get currentUser => _auth.currentUser;

  /// Stream for auth state changes — used to decide initial route
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email + password, then create Firestore profile
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Update display name
    await credential.user?.updateDisplayName(name);
    // Create Firestore profile
    if (credential.user != null) {
      await FirestoreService().createUserProfile(
        uid: credential.user!.uid,
        name: name,
        email: email,
      );
    }
    return credential;
  }

  /// Sign in with email + password.
  /// Also ensures a Firestore profile exists — recovers accounts that were
  /// created before the database was set up.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      final existing = await FirestoreService().getUserProfile(user.uid);
      if (existing == null) {
        // Profile missing — create it now (happens if DB didn't exist at sign-up)
        final name = user.displayName ?? user.email?.split('@').first ?? 'User';
        await FirestoreService().createUserProfile(
          uid: user.uid,
          name: name,
          email: user.email ?? email,
        );
      }
    }
    return credential;
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web sign in
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        final credential = await _auth.signInWithPopup(authProvider);
        await _ensureFirestoreProfile(credential.user);
        return credential;
      } else {
        // Mobile sign in using google_sign_in 7.x API
        final googleUser = await GoogleSignIn.instance.authenticate();

        final idToken = googleUser.authentication.idToken;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        await _ensureFirestoreProfile(userCredential.user);
        return userCredential;
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // The user canceled the sign-in
        return null;
      }
      if (kDebugMode) print('[FirebaseAuthService] Google Sign-In error: $e');
      rethrow;
    } catch (e) {
      if (kDebugMode) print('[FirebaseAuthService] Google Sign-In error: $e');
      rethrow;
    }
  }

  Future<void> _ensureFirestoreProfile(User? user) async {
    if (user != null) {
      final existing = await FirestoreService().getUserProfile(user.uid);
      if (existing == null) {
        final name = user.displayName ?? user.email?.split('@').first ?? 'User';
        await FirestoreService().createUserProfile(
          uid: user.uid,
          name: name,
          email: user.email ?? '',
        );
      }
    }
  }

  // ─── Email OTP Two-Phase Auth ───────────────────────────────────────────────

  /// Phase 1 (Login): Validate credentials via REST API to avoid triggering
  /// local authStateChanges prematurely. Returns `null` on success.
  Future<String?> prepareLogin({
    required String email,
    required String password,
  }) async {
    try {
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
      );

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (res.statusCode != 200) {
        // Try to parse JSON error, fallback to generic message
        try {
          final data = jsonDecode(res.body);
          if (data['error'] != null) {
            final msg = data['error']['message'] as String;
            if (msg.contains('INVALID_LOGIN_CREDENTIALS') ||
                msg.contains('INVALID_PASSWORD') ||
                msg.contains('EMAIL_NOT_FOUND')) {
              return 'Invalid email or password.';
            } else if (msg.contains('USER_DISABLED')) {
              return 'This account has been disabled.';
            } else if (msg.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
              return 'Too many attempts. Please try again later.';
            }
            return 'Login failed. Please try again.';
          }
        } catch (_) {
          // Response was not JSON (HTML error page)
        }
        return 'Login failed. Please check your connection and try again.';
      }
      return null;
    } catch (e) {
      return 'Network error. Please try again.';
    }
  }

  /// Phase 1 (Sign Up): Create account via REST API to avoid triggering
  /// local authStateChanges prematurely. Returns `null` on success.
  ///
  /// Edge-case handled: if the email was already registered in a PREVIOUS
  /// abandoned OTP flow, we check password. If it matches, we allow standard OTP verify.
  Future<String?> prepareSignUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
      );

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (res.statusCode != 200) {
        try {
          final data = jsonDecode(res.body);
          if (data['error'] != null) {
            final msg = data['error']['message'] as String;
            if (msg.contains('EMAIL_EXISTS') ||
                msg.contains('FEDERATED_USER_ID_ALREADY_LINKED')) {
              // Check if password matches to handle abandoned OTP flow
              final loginCheck = await prepareLogin(
                email: email,
                password: password,
              );
              if (loginCheck == null) {
                return null;
              }
              return 'This email is already registered. Please go to Login instead.';
            } else if (msg.contains('WEAK_PASSWORD')) {
              return 'Password must be at least 6 characters.';
            } else if (msg.contains('INVALID_EMAIL')) {
              return 'Please enter a valid email address.';
            } else if (msg.contains('ADMIN_ONLY_OPERATION') ||
                msg.contains('OPERATION_NOT_ALLOWED')) {
              return 'Email/password sign-up is not enabled. Contact support.';
            } else if (msg.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
              return 'Too many attempts. Please try again later.';
            }
          }
        } catch (_) {
          // Response was not JSON (HTML error page)
        }
        return 'Sign-up failed. Please try again.';
      }
      return null;
    } catch (e) {
      return 'Network error. Please try again.';
    }
  }

  /// Phase 2: Final sign-in after OTP is verified. This triggers the
  /// `authStateChanges` stream which auto-navigates to MainLayout.
  Future<String?> completeSignIn({
    required String email,
    required String password,
    String? name, // Passed during sign up to set display name
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        if (name != null && name.isNotEmpty) {
          await user.updateDisplayName(name);
        }
        final existing = await FirestoreService().getUserProfile(user.uid);
        if (existing == null) {
          await FirestoreService().createUserProfile(
            uid: user.uid,
            name: name ?? user.displayName ?? email.split('@').first,
            email: email,
          );
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return friendlyError(e);
    } catch (e) {
      return 'Sign-in failed. Please try again.';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Phone Authentication ──────────────────────────────────────────────────

  /// Sends OTP to the given phone number.
  /// [onCodeSent] is called with the verificationId and resendToken when
  /// Firebase sends the SMS code.
  /// [onAutoVerified] is called when Android auto-verifies the code.
  /// [onFailed] is called with a friendly error message on failure.
  /// [onTimeout] is called when the auto-retrieval timer expires.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(UserCredential credential) onAutoVerified,
    required void Function(String error) onFailed,
    required void Function(String verificationId) onTimeout,
    int? forceResendingToken,
  }) async {
    if (kDebugMode) {
      print('[PhoneAuth] Starting verification for: $phoneNumber');
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (kDebugMode) {
          print('[PhoneAuth] verificationCompleted called (auto-verify)');
        }
        try {
          final userCredential = await _auth.signInWithCredential(credential);
          if (userCredential.user != null) {
            final existing = await FirestoreService().getUserProfile(
              userCredential.user!.uid,
            );
            if (existing == null) {
              await FirestoreService().createUserProfile(
                uid: userCredential.user!.uid,
                name: userCredential.user!.phoneNumber ?? 'User',
                email: userCredential.user!.email ?? '',
              );
            }
          }
          onAutoVerified(userCredential);
        } catch (e) {
          if (kDebugMode) print('[PhoneAuth] Auto-verify sign-in failed: $e');
          onFailed('Auto-verification failed. Please enter the code manually.');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        // ⬇ Always print full details so you can see the real error in the console
        if (kDebugMode) {
          print('[PhoneAuth] ❌ verificationFailed!');
          print('[PhoneAuth]   code    : ${e.code}');
          print('[PhoneAuth]   message : ${e.message}');
          print('[PhoneAuth]   details : ${e.stackTrace}');
        }
        // In debug mode, append the raw code and message to the user-facing message
        final friendly = friendlyError(e);
        final debugInfo = '[debug: ${e.code}] ${e.message ?? ""}';
        onFailed(kDebugMode ? '$friendly\n$debugInfo' : friendly);
      },
      codeSent: (String verificationId, int? resendToken) {
        if (kDebugMode) {
          print('[PhoneAuth] ✅ codeSent — verificationId: $verificationId');
        }
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (kDebugMode) print('[PhoneAuth] ⏰ codeAutoRetrievalTimeout');
        onTimeout(verificationId);
      },
    );
  }

  /// Verifies the OTP code entered by the user.
  /// Returns the [UserCredential] on success.
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    if (kDebugMode) {
      print(
        '[PhoneAuth] Verifying OTP: $otp (verificationId length: ${verificationId.length})',
      );
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      if (kDebugMode) {
        print('[PhoneAuth] ✅ OTP verified! UID: ${userCredential.user?.uid}');
      }

      // Ensure Firestore profile exists for phone-auth users
      if (userCredential.user != null) {
        final existing = await FirestoreService().getUserProfile(
          userCredential.user!.uid,
        );
        if (existing == null) {
          await FirestoreService().createUserProfile(
            uid: userCredential.user!.uid,
            name: userCredential.user!.phoneNumber ?? 'User',
            email: userCredential.user!.email ?? '',
          );
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('[PhoneAuth] ❌ OTP verification failed!');
        print('[PhoneAuth]   code    : ${e.code}');
        print('[PhoneAuth]   message : ${e.message}');
      }
      rethrow;
    }
  }

  /// Human-readable error messages from Firebase auth error codes
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Check your network.';
      case 'invalid-phone-number':
        return 'Invalid phone number. Please include country code (e.g. +91).';
      case 'invalid-verification-code':
        return 'Wrong OTP. Please check and try again.';
      case 'session-expired':
        return 'OTP has expired. Please request a new one.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Try again later.';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Invalid email or password.';
      case 'channel-error':
        return 'Please fill in all fields correctly.';
      case 'missing-email':
        return 'Please enter your email address.';
      default:
        if (kDebugMode) print('[Auth Error] ${e.code}: ${e.message}');
        return 'Something went wrong. Please try again.';
    }
  }

  // ─── Forgot Password (REST API) ──────────────────────────────────────────

  /// Send a password reset email via REST API.
  /// Returns `null` on success, or an error message.
  Future<String?> sendPasswordResetViaRest(String email) async {
    try {
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$apiKey',
      );

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestType': 'PASSWORD_RESET',
          'email': email,
        }),
      );

      if (res.statusCode == 200) return null;

      try {
        final data = jsonDecode(res.body);
        if (data['error'] != null) {
          final msg = data['error']['message'] as String;
          if (msg.contains('EMAIL_NOT_FOUND')) {
            return 'No account found with this email.';
          } else if (msg.contains('INVALID_EMAIL')) {
            return 'Please enter a valid email address.';
          } else if (msg.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
            return 'Too many attempts. Please try again later.';
          }
        }
      } catch (_) {}
      return 'Could not send reset email. Please try again.';
    } catch (e) {
      return 'Network error. Please try again.';
    }
  }

  /// Confirm password reset using the oobCode from the email link.
  /// Returns `null` on success, or an error message.
  Future<String?> confirmPasswordResetViaRest({
    required String oobCode,
    required String newPassword,
  }) async {
    try {
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:resetPassword?key=$apiKey',
      );

      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'oobCode': oobCode,
          'newPassword': newPassword,
        }),
      );

      if (res.statusCode == 200) return null;

      try {
        final data = jsonDecode(res.body);
        if (data['error'] != null) {
          final msg = data['error']['message'] as String;
          if (msg.contains('EXPIRED_OOB_CODE')) {
            return 'This reset link has expired. Please request a new one.';
          } else if (msg.contains('INVALID_OOB_CODE')) {
            return 'Invalid reset code. Please check and try again.';
          } else if (msg.contains('WEAK_PASSWORD')) {
            return 'Password must be at least 6 characters.';
          }
        }
      } catch (_) {}
      return 'Password reset failed. Please try again.';
    } catch (e) {
      return 'Network error. Please try again.';
    }
  }
}
