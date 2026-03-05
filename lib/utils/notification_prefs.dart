import 'package:shared_preferences/shared_preferences.dart';

/// Notification categories
enum NotificationType {
  txSuccess,
  txFailed,
  cashback,
  rewards,
  securityAlerts,
  promoOffers,
  pushNotifications,
}

/// Singleton that reads/writes individual notification toggle preferences.
/// All flows (payment, cashback, etc.) must call [isEnabled] before
/// triggering an in-app notification.
class NotificationPrefs {
  static final NotificationPrefs _instance = NotificationPrefs._internal();
  factory NotificationPrefs() => _instance;
  NotificationPrefs._internal();

  static const Map<NotificationType, String> _keys = {
    NotificationType.txSuccess: 'notif_tx_success',
    NotificationType.txFailed: 'notif_tx_failed',
    NotificationType.cashback: 'notif_cashback',
    NotificationType.rewards: 'notif_rewards',
    NotificationType.securityAlerts: 'notif_security',
    NotificationType.promoOffers: 'notif_promo',
    NotificationType.pushNotifications: 'notif_push',
  };

  static const Map<NotificationType, bool> _defaults = {
    NotificationType.txSuccess: true,
    NotificationType.txFailed: true,
    NotificationType.cashback: true,
    NotificationType.rewards: true,
    NotificationType.securityAlerts: true,
    NotificationType.promoOffers: false,
    NotificationType.pushNotifications: true,
  };

  Future<bool> isEnabled(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keys[type]!) ?? (_defaults[type] ?? true);
  }

  Future<void> setEnabled(NotificationType type, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keys[type]!, value);
  }

  Future<Map<NotificationType, bool>> getAllPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <NotificationType, bool>{};
    for (final entry in _keys.entries) {
      result[entry.key] =
          prefs.getBool(entry.value) ?? (_defaults[entry.key] ?? true);
    }
    return result;
  }
}
