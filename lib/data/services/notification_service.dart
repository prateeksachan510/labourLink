import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:labour_link/core/constants/app_constants.dart';
import 'package:labour_link/core/constants/firebase_paths.dart';
import 'package:labour_link/data/services/firebase_service.dart';

/// Top-level background message handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[FCM] Background message received: ${message.messageId} '
    'title=${message.notification?.title}',
  );
}

/// Handles FCM token storage, foreground notifications, and sending
/// push notifications to other users via the FCM Legacy HTTP API.
class NotificationService {
  NotificationService._();

  static final _fln = FlutterLocalNotificationsPlugin();
  static final _fcm = FirebaseMessaging.instance;
  static bool _initialized = false;

  static const _channelId = 'labourlink_main';
  static const _channelName = 'LabourLink Notifications';

  // ── Initialization ────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[NotificationService] Initializing…');

    // Request permission (iOS + Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint(
      '[NotificationService] Permission status: ${settings.authorizationStatus}',
    );

    // Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Real-time updates for LabourLink',
      importance: Importance.high,
    );
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Init flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _fln.initialize(initSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        '[NotificationService] Foreground message: ${message.messageId} '
        'title=${message.notification?.title}',
      );
      final notification = message.notification;
      if (notification == null) return;
      _fln.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    debugPrint('[NotificationService] Initialized successfully');
  }

  // ── Token management ──────────────────────────────────────────────────────

  /// Fetches FCM token and saves it to Users/{uid}/fcmToken.
  static Future<void> saveFcmToken(String uid) async {
    if (uid.isEmpty) return;
    try {
      final token = await _fcm.getToken();
      if (token == null) {
        debugPrint('[NotificationService] FCM token null for uid=$uid');
        return;
      }
      await FirebaseService.db
          .ref(FirebasePaths.users)
          .child(uid)
          .update({'fcmToken': token});
      debugPrint(
        '[NotificationService] FCM token saved uid=$uid token=${token.substring(0, 20)}…',
      );
    } catch (e) {
      debugPrint('[NotificationService] saveFcmToken error: $e');
    }
  }

  // ── Sending notifications ─────────────────────────────────────────────────

  /// Sends a push notification to [toUserId] via FCM Legacy HTTP API.
  /// Fetches the recipient's fcmToken from Firebase before sending.
  static Future<void> sendToUser({
    required String toUserId,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    if (AppConstants.fcmServerKey == 'YOUR_FCM_SERVER_KEY_HERE') {
      debugPrint(
        '[NotificationService] FCM server key not configured — skipping send '
        'to uid=$toUserId title="$title"',
      );
      return;
    }
    try {
      // Fetch the recipient's FCM token
      final snapshot = await FirebaseService.db
          .ref(FirebasePaths.users)
          .child(toUserId)
          .child('fcmToken')
          .get();
      if (!snapshot.exists || snapshot.value == null) {
        debugPrint(
          '[NotificationService] No FCM token for uid=$toUserId — notification skipped',
        );
        return;
      }
      final token = snapshot.value.toString();
      debugPrint(
        '[NotificationService] Sending notification to uid=$toUserId '
        'title="$title" body="$body"',
      );

      final response = await http.post(
        Uri.parse(AppConstants.fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=${AppConstants.fcmServerKey}',
        },
        body: jsonEncode({
          'to': token,
          'priority': 'high',
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': data,
        }),
      );
      debugPrint(
        '[NotificationService] FCM response: ${response.statusCode} '
        '${response.body.length > 100 ? response.body.substring(0, 100) : response.body}',
      );
    } catch (e) {
      debugPrint('[NotificationService] sendToUser error: $e');
    }
  }
}

/// Helper to fetch a user's FCM token from the DB.
Future<String?> getFcmToken(String uid) async {
  try {
    final snap = await FirebaseService.db
        .ref(FirebasePaths.users)
        .child(uid)
        .child('fcmToken')
        .get();
    if (!snap.exists || snap.value == null) return null;
    return snap.value.toString();
  } catch (_) {
    return null;
  }
}
