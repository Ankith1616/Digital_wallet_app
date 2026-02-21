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
      default:
        if (kDebugMode) print('[Auth Error] ${e.code}: ${e.message}');
        return 'Something went wrong. Please try again.';
    }
  }
}
