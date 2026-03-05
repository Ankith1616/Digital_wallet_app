import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Result of an OTP verification attempt.
enum OtpVerifyResult { valid, expired, wrong, notFound }

// ─────────────────────────────────────────────────────────────────────────────
// EmailJS Configuration
// ─────────────────────────────────────────────────────────────────────────────
//
// 1. Go to https://www.emailjs.com and create a free account.
// 2. Create an Email Service (Gmail recommended) → note the SERVICE ID.
// 3. Create an Email Template with these template variables:
//    - Subject:  Your DigiPe Verification Code
//    - Body:
//        Hello,
//        Your OTP for DigiPe is: {{otp}}
//        This code expires in 5 minutes.
//        Do not share this with anyone.
//    → Note the TEMPLATE ID.
// 4. Copy your PUBLIC KEY from Account → API Keys.
// 5. Fill in the three constants below.
//
// Template variables used:
//   {{to_email}}   → recipient's email address
//   {{otp}}        → the 6-digit code
//   {{app_name}}   → "DigiPe"
// ─────────────────────────────────────────────────────────────────────────────

class EmailOtpService {
  static final EmailOtpService _instance = EmailOtpService._internal();
  factory EmailOtpService() => _instance;
  EmailOtpService._internal();

  // ── CONFIGURE THESE ────────────────────────────────────────────────────────
  static const String _emailJsServiceId = 'service_q0ew1ht';
  static const String _emailJsTemplateId = 'template_gx5pxsc';
  static const String _emailJsPublicKey = 'AjjELeucm-wEo7cwh';
  // ───────────────────────────────────────────────────────────────────────────

  static const String _emailJsEndpoint =
      'https://api.emailjs.com/api/v1.0/email/send';
  static const int _otpExpiryMinutes = 5;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Converts an email address into a safe Firestore document ID.
  String _docId(String email) =>
      email.toLowerCase().replaceAll(RegExp(r'[.@+]'), '_');

  /// Gets the standard Firestore instance
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── OTP Generation ──────────────────────────────────────────────────────────

  /// Generates a cryptographically-random 6-digit OTP string.
  String generateOtp() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  // ── Firestore Storage (Standard SDK) ──────

  /// Saves the OTP to Firestore with a 5-minute expiry timestamp.
  Future<void> saveOtp(String email, String otp) async {
    try {
      final docId = _docId(email);
      final expiresAt = DateTime.now()
          .add(const Duration(minutes: _otpExpiryMinutes))
          .millisecondsSinceEpoch;

      await _db.collection('email_otps').doc(docId).set({
        'otp': otp,
        'email': email.toLowerCase(),
        'expiresAt': expiresAt,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving OTP to Firestore: $e');
      // We throw the error so the caller knows it failed and doesn't tell the user "OTP sent"
      // if it wasn't actually saved in the DB.
      throw Exception('Failed to save OTP to database');
    }
  }

  /// Verifies the entered OTP against the Firestore record.
  Future<OtpVerifyResult> verifyOtp(String email, String enteredOtp) async {
    try {
      final docId = _docId(email);
      final doc = await _db.collection('email_otps').doc(docId).get();

      if (!doc.exists) return OtpVerifyResult.notFound;

      final data = doc.data()!;
      final storedOtp = data['otp']?.toString().trim() ?? '';

      // Safely parse the expiration time regardless of whether it comes back as int/double/string
      final expiresAtRaw = data['expiresAt'];
      final expiresAt = int.tryParse(expiresAtRaw?.toString() ?? '0') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now > expiresAt) return OtpVerifyResult.expired;
      if (enteredOtp.trim() != storedOtp) return OtpVerifyResult.wrong;

      return OtpVerifyResult.valid;
    } catch (e) {
      debugPrint('Error verifying OTP from Firestore: $e');
      return OtpVerifyResult.notFound;
    }
  }

  /// Deletes the OTP record after successful verification.
  Future<void> clearOtp(String email) async {
    try {
      final docId = _docId(email);
      await _db.collection('email_otps').doc(docId).delete();
    } catch (_) {
      // Non-critical — swallow any errors on cleanup.
    }
  }

  // ── EmailJS Delivery ────────────────────────────────────────────────────────

  /// Sends the OTP to [toEmail] via the EmailJS REST API.
  ///
  /// Returns `null` on success, or an error message string on failure.
  Future<String?> sendOtpEmail(String toEmail, String otp) async {
    // Guard: config not yet filled in
    if (_emailJsServiceId == 'YOUR_SERVICE_ID' ||
        _emailJsTemplateId == 'YOUR_TEMPLATE_ID' ||
        _emailJsPublicKey == 'YOUR_PUBLIC_KEY') {
      return 'EmailJS is not configured. '
          'Fill in the constants in email_otp_service.dart.';
    }

    try {
      final response = await http
          .post(
            Uri.parse(_emailJsEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'origin': 'http://localhost', // required by EmailJS
            },
            body: jsonEncode({
              'service_id': _emailJsServiceId,
              'template_id': _emailJsTemplateId,
              'user_id': _emailJsPublicKey,
              'template_params': {
                'to_email': toEmail, // → "To Email" field   {{to_email}}
                'otp': otp, // → body               {{otp}}
                'name': 'DigiPe', // → "From Name" field  {{name}}
                'email': toEmail, // → "Reply To" field   {{email}}
                'app_name': 'DigiPe',
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return null; // success
      }
      // EmailJS returns plain-text error descriptions on failure
      return 'EmailJS error (${response.statusCode}): ${response.body}';
    } catch (e) {
      return 'Network error: ${e.toString()}';
    }
  }
}
