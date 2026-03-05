import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../models/app_notification.dart';

/// Result of a biometric authentication attempt.
class BiometricAuthResult {
  final bool success;
  final String? errorMessage;
  const BiometricAuthResult._(this.success, [this.errorMessage]);

  static const BiometricAuthResult ok = BiometricAuthResult._(true);
  factory BiometricAuthResult.fail(String message) =>
      BiometricAuthResult._(false, message);
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Storage key for Transaction PIN
  static const String _pinKey = 'user_pin';
  // Storage key for Digi PIN (App Lock — separate from Transaction PIN)
  static const String _digiPinKey = 'digi_pin';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _instantPayEnabledKey = 'instant_pay_enabled';
  static const String _instantLimitKey = 'instant_limit';
  static const String _instantDailyUsageKey = 'instant_daily_usage';
  static const String _instantLastDateKey = 'instant_last_date';
  static const double maxDailyInstantLimit = 2000.0;

  // Storage keys for Biometric Pay daily limit
  static const String _biometricDailyUsageKey = 'biometric_daily_usage';
  static const double maxDailyBiometricLimit = 5000.0;

  // Storage keys for Biometric Login credentials
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  // State
  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  bool _isInstantPayEnabled = false;
  bool get isInstantPayEnabled => _isInstantPayEnabled;

  double _instantLimit = 1000.0;
  double get instantLimit => _instantLimit;

  /// Alias: biometric limit is the same as instantLimit
  double get biometricTransactionLimit => _instantLimit;

  double _instantDailyUsage = 0.0;
  double get instantDailyUsage => _instantDailyUsage;

  double _biometricDailyUsage = 0.0;
  double get biometricDailyUsage => _biometricDailyUsage;

  /// Returns true if biometric is enabled AND the amount exceeds the threshold.
  /// Payment flows should call biometric first, then fall back to PIN.
  bool requiresBiometric(double amount) {
    return _isBiometricEnabled && amount > _instantLimit;
  }

  /// Initialize auth settings
  Future<void> init() async {
    String? bioEnabled = await _storage.read(key: _biometricEnabledKey);
    _isBiometricEnabled = bioEnabled == 'true';

    String? instantEnabled = await _storage.read(key: _instantPayEnabledKey);
    _isInstantPayEnabled = instantEnabled == 'true';

    String? limitStr = await _storage.read(key: _instantLimitKey);
    _instantLimit = double.tryParse(limitStr ?? '500.0') ?? 500.0;

    await _checkAndResetDailyUsage();
  }

  Future<void> _checkAndResetDailyUsage() async {
    String? lastDate = await _storage.read(key: _instantLastDateKey);
    String today = DateTime.now().toIso8601String().split('T')[0];

    if (lastDate != today) {
      _instantDailyUsage = 0.0;
      _biometricDailyUsage = 0.0;
      await _storage.write(key: _instantDailyUsageKey, value: '0.0');
      await _storage.write(key: _biometricDailyUsageKey, value: '0.0');
      await _storage.write(key: _instantLastDateKey, value: today);
    } else {
      String? usageStr = await _storage.read(key: _instantDailyUsageKey);
      _instantDailyUsage = double.tryParse(usageStr ?? '0.0') ?? 0.0;

      String? bioUsageStr = await _storage.read(key: _biometricDailyUsageKey);
      _biometricDailyUsage = double.tryParse(bioUsageStr ?? '0.0') ?? 0.0;
    }
  }

  /// Check if Instant Pay can be processed for a given amount
  bool canProcessInstantPay(double amount) {
    if (!_isInstantPayEnabled) return false;
    if (amount > _instantLimit) return false;
    if (_instantDailyUsage + amount > maxDailyInstantLimit) return false;
    return true;
  }

  /// Record usage after successful Instant Pay
  Future<void> recordInstantPayUsage(double amount) async {
    await _checkAndResetDailyUsage();
    _instantDailyUsage += amount;
    await _storage.write(
      key: _instantDailyUsageKey,
      value: _instantDailyUsage.toString(),
    );
  }

  /// Check if Biometric Pay can be processed
  bool canProcessBiometricPay(double amount) {
    if (!_isBiometricEnabled) return false;
    if (_biometricDailyUsage + amount > maxDailyBiometricLimit) return false;
    return true;
  }

  /// Record usage after successful Biometric Pay
  Future<void> recordBiometricUsage(double amount) async {
    await _checkAndResetDailyUsage();
    _biometricDailyUsage += amount;
    await _storage.write(
      key: _biometricDailyUsageKey,
      value: _biometricDailyUsage.toString(),
    );
  }

  /// Save credentials for Biometric Login
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _savedEmailKey, value: email);
    await _storage.write(key: _savedPasswordKey, value: password);
  }

  /// Get saved credentials for Biometric Login
  Future<Map<String, String>?> getSavedCredentials() async {
    final email = await _storage.read(key: _savedEmailKey);
    final password = await _storage.read(key: _savedPasswordKey);
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  /// Clear saved credentials
  Future<void> clearSavedCredentials() async {
    await _storage.delete(key: _savedEmailKey);
    await _storage.delete(key: _savedPasswordKey);
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

    // Trigger notification
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirestoreService().addNotification(
        uid,
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: "Security Alert 🛡️",
          message: "Your application PIN has been successfully updated.",
          date: DateTime.now(),
          type: NotificationType.security,
        ),
      );
    }
  }

  /// Toggle Biometric Enabled
  Future<void> toggleBiometric(bool enabled) async {
    _isBiometricEnabled = enabled;
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
    if (!enabled) {
      await clearSavedCredentials();
    }
  }

  /// Toggle Instant Pay
  Future<void> toggleInstantPay(bool enabled) async {
    _isInstantPayEnabled = enabled;
    await _storage.write(key: _instantPayEnabledKey, value: enabled.toString());
  }

  /// Set Instant Payment Limit
  Future<void> setInstantLimit(double limit) async {
    _instantLimit = limit;
    await _storage.write(key: _instantLimitKey, value: limit.toString());
  }

  /// Authenticate with Biometrics (simple bool for existing callers)
  Future<bool> authenticateBiometrics() async {
    final result = await authenticateBiometricsDetailed();
    return result.success;
  }

  /// Authenticate with detailed result for UI feedback
  Future<BiometricAuthResult> authenticateBiometricsDetailed() async {
    try {
      bool isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        return BiometricAuthResult.fail(
          'This device does not support biometric authentication',
        );
      }

      bool canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        return BiometricAuthResult.fail(
          'Biometrics are not available on this device. '
          'Please check your device settings',
        );
      }

      final enrolled = await _localAuth.getAvailableBiometrics();
      if (enrolled.isEmpty) {
        return BiometricAuthResult.fail(
          'No biometrics enrolled. Please set up fingerprint or '
          'face unlock in your device settings',
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to enable Biometric Pay',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return authenticated
          ? BiometricAuthResult.ok
          : BiometricAuthResult.fail(
              'Biometric verification cancelled or failed',
            );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Biometric PlatformException: code=${e.code}, msg=${e.message}');
      }
      final msg = switch (e.code) {
        auth_error.notAvailable =>
          'Biometric hardware not available on this device',
        auth_error.notEnrolled =>
          'No biometrics enrolled. Please set up fingerprint or '
          'face unlock in your device settings',
        auth_error.passcodeNotSet =>
          'No screen lock set up. Please set a PIN, pattern, or '
          'password in your device settings first',
        auth_error.lockedOut =>
          'Too many failed attempts. Biometrics are temporarily locked',
        auth_error.permanentlyLockedOut =>
          'Biometrics are permanently locked. Please unlock your '
          'device using your PIN/password',
        _ => 'Biometric error: ${e.message ?? e.code}',
      };
      return BiometricAuthResult.fail(msg);
    }
  }

  // ─── Digi PIN (App Lock) ────────────────────────────────────────────

  /// Returns true if a Digi PIN has been set (app lock).
  Future<bool> hasDigiPin() async {
    final pin = await _storage.read(key: _digiPinKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Set or change the Digi PIN.
  Future<void> setDigiPin(String pin) async {
    await _storage.write(key: _digiPinKey, value: pin);
  }

  /// Verify the entered Digi PIN. Returns true if correct.
  Future<bool> verifyDigiPin(String enteredPin) async {
    final stored = await _storage.read(key: _digiPinKey);
    if (stored == null || stored.isEmpty) return false;
    return stored == enteredPin;
  }

  /// Clear the Digi PIN (disables app lock).
  Future<void> clearDigiPin() async {
    await _storage.delete(key: _digiPinKey);
  }
}
