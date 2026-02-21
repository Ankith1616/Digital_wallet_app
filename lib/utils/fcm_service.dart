import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

/// Top-level background message handler (must be top-level, not a class method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this runs
  if (kDebugMode) {
    print(
      '[FCM Background] ${message.notification?.title}: ${message.notification?.body}',
    );
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Must be called after Firebase.initializeApp() and after user logs in
  Future<void> init({required String uid}) async {
    // 1. Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('[FCM] Permission status: ${settings.authorizationStatus}');
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 2. Get token and save to Firestore
    final token = await _messaging.getToken();
    if (token != null) {
      await FirestoreService().saveFcmToken(uid, token);
      if (kDebugMode) print('[FCM] Token saved: $token');
    }

    // 3. Refresh token listener
    _messaging.onTokenRefresh.listen((newToken) async {
      await FirestoreService().saveFcmToken(uid, newToken);
    });
  }

  /// Call once at app start to register background handler
  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Returns a stream of foreground messages — listen to this in your UI
  /// to show in-app banners when a notification arrives
  Stream<RemoteMessage> get foregroundMessages => FirebaseMessaging.onMessage;
}
