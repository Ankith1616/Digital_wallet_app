import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashHelper {
  /// Generates a SHA-256 hash of the provided plain text PIN
  static String hashPin(String pin) {
    var bytes = utf8.encode(pin);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies a plain text PIN against a stored SHA-256 hash
  static bool verifyPin(String pin, String hash) {
    return hashPin(pin) == hash;
  }
}

