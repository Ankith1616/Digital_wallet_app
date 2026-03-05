import 'package:flutter/material.dart';
import '../../models/notification_preferences.dart';
import '../../utils/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationPreferences _prefs = NotificationPreferences();
  bool _loading = false;

  NotificationPreferences get prefs => _prefs;
  bool get loading => _loading;

  NotificationProvider() {
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _loading = true;
    notifyListeners();

    _prefs = await FirestoreService().getNotificationPreferences(user.uid);
    _loading = false;
    notifyListeners();
  }

  Future<void> togglePreference(String field, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Optimistic Update
    final oldPrefs = _prefs;
    switch (field) {
      case 'transactionSuccess':
        _prefs = _prefs.copyWith(transactionSuccess: value);
        break;
      case 'transactionFailed':
        _prefs = _prefs.copyWith(transactionFailed: value);
        break;
      case 'cashbackEarned':
        _prefs = _prefs.copyWith(cashbackEarned: value);
        break;
      case 'rewardsOffers':
        _prefs = _prefs.copyWith(rewardsOffers: value);
        break;
      case 'promotionalOffers':
        _prefs = _prefs.copyWith(promotionalOffers: value);
        break;
      case 'securityAlerts':
        _prefs = _prefs.copyWith(securityAlerts: value);
        break;
      case 'pushNotifications':
        _prefs = _prefs.copyWith(pushNotifications: value);
        break;
    }
    notifyListeners();

    try {
      await FirestoreService().updateNotificationPreferences(user.uid, _prefs);
    } catch (e) {
      // Revert on failure
      _prefs = oldPrefs;
      notifyListeners();
    }
  }
}
