import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../data/notification_store.dart';

class NotificationService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static String? _currentToken;

  static Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint(
        'Notification permission: ${settings.authorizationStatus}',
      );

      _currentToken = await _messaging.getToken();

      debugPrint('FCM token received.');

      // Try immediately in case a user is already logged in.
      await saveCurrentToken();

      // Save again whenever the user logs in/out.
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          await saveCurrentToken();
          await notificationStore.loadNotifications();
        }
      });

      // Token can change in the future.
      _messaging.onTokenRefresh.listen((newToken) async {
        _currentToken = newToken;
        debugPrint('FCM token refreshed.');
        await saveCurrentToken();
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          'Notification received: ${message.notification?.title}',
        );
        debugPrint(
          'Notification body: ${message.notification?.body}',
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          'Notification opened: ${message.notification?.title}',
        );
      });
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  }

  static Future<void> saveCurrentToken() async {
    final token = _currentToken;

    if (token == null) {
      debugPrint('No FCM token available yet.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('No logged-in user. Token will be saved after login.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('FCM token saved to Firestore.');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }
}
