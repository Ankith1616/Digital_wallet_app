import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../models/app_notification.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Storage key for PIN
  static const String _pinKey = 'user_pin';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _instantPayEnabledKey = 'instant_pay_enabled';
  static const String _instantLimitKey = 'instant_limit';
  static const String _instantDailyUsageKey = 'instant_daily_usage';
  static const String _instantLastDateKey = 'instant_last_date';
  static const double maxDailyInstantLimit = 2000.0;

  // State
  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  bool _isInstantPayEnabled = false;
  bool get isInstantPayEnabled => _isInstantPayEnabled;

  double _instantLimit = 500.0;
  double get instantLimit => _instantLimit;

  double _instantDailyUsage = 0.0;
  double get instantDailyUsage => _instantDailyUsage;

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
      await _storage.write(key: _instantDailyUsageKey, value: '0.0');
      await _storage.write(key: _instantLastDateKey, value: today);
    } else {
      String? usageStr = await _storage.read(key: _instantDailyUsageKey);
      _instantDailyUsage = double.tryParse(usageStr ?? '0.0') ?? 0.0;
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
    await _checkAndResetDailyUsage(); // Ensure it's for today
    _instantDailyUsage += amount;
    await _storage.write(
      key: _instantDailyUsageKey,
      value: _instantDailyUsage.toString(),
    );
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
