import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

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
      default:
        if (kDebugMode) print('[Auth Error] ${e.code}: ${e.message}');
        return 'Something went wrong. Please try again.';
    }
  }
}

