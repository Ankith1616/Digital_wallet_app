import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Storage key for PIN
  static const String _pinKey = 'user_pin';
  static const String _biometricEnabledKey = 'biometric_enabled';

  // State
  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  /// Initialize auth settings
  Future<void> init() async {
    String? bioEnabled = await _storage.read(key: _biometricEnabledKey);
    _isBiometricEnabled = bioEnabled == 'true';
  }

  /// Check if a PIN is set
  Future<bool> hasPin() async {
    String? pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Verify entered PIN
  Future<bool> verifyPin(String enteredPin) async {
    String? storedPin = await _storage.read(key: _pinKey);
    // For demo purposes, allow "1234" if no PIN is set
    if (storedPin == null) return enteredPin == "1234";
    return storedPin == enteredPin;
  }

  /// Set or Update PIN
  Future<void> setPin(String newPin) async {
    await _storage.write(key: _pinKey, value: newPin);
  }

  /// Toggle Biometric Enabled
  Future<void> toggleBiometric(bool enabled) async {
    _isBiometricEnabled = enabled;
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  /// Authenticate with Biometrics
  Future<bool> authenticateBiometrics() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Biometric Error: $e");
      }
      return false;
    }
  }
}
