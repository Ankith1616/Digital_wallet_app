import '../../utils/firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Fetches preferences and checks if a notification should be sent
  Future<bool> shouldSendNotification(String uid, String category) async {
    final prefs = await FirestoreService().getNotificationPreferences(uid);

    // 1. Check Master Toggle
    if (!prefs.pushNotifications) return false;

    // 2. Check Specific Category
    switch (category) {
      case 'transactionSuccess':
        return prefs.transactionSuccess;
      case 'transactionFailed':
        return prefs.transactionFailed;
      case 'cashbackEarned':
        return prefs.cashbackEarned;
      case 'rewardsOffers':
        return prefs.rewardsOffers;
      case 'promotionalOffers':
        return prefs.promotionalOffers;
      case 'securityAlerts':
        return prefs.securityAlerts;
      default:
        return true; // Default to allow if category is not mapped
    }
  }
}
