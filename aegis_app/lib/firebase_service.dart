import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _fcmToken;

  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      print('✅ Firebase initialized');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request notification permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permission granted');
      } else {
        print('⚠️ Notification permission denied');
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        print('📱 FCM Token: $_fcmToken');
        await _sendTokenToBackend(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _sendTokenToBackend(newToken);
      });

      // Handle foreground messages - SHOW LOCAL NOTIFICATION
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Foreground message received');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
        
        // Show local notification even when app is open
        _showLocalNotification(
          message.notification?.title ?? '🚨 AegisAI Alert',
          message.notification?.body ?? 'Emergency alert received',
          message.data,
        );
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification tap (app opened from notification)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📱 Notification tapped, app opened');
        print('Data: ${message.data}');
      });

    } catch (e) {
      print('❌ Firebase initialization error: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('📱 Local notification tapped: ${response.payload}');
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'aegis_alerts',
      'AegisAI Alerts',
      description: 'Emergency alerts from AegisAI',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _showLocalNotification(String title, String body, Map<String, dynamic> data) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'aegis_alerts',
      'AegisAI Alerts',
      channelDescription: 'Emergency alerts from AegisAI',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: jsonEncode(data),
    );
    
    print('🔔 Local notification shown: $title - $body');
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceToken = prefs.getString('device_token');
      
      if (deviceToken == null) {
        print('⚠️ No device token found, skipping FCM token sync');
        return;
      }

      const baseUrl = 'http://192.168.1.34:8000';
      final url = Uri.parse('$baseUrl/api/v1/device/update-fcm-token/');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_token': deviceToken,
          'fcm_token': token,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token sent to backend');
      } else {
        print('⚠️ Failed to send FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending FCM token to backend: $e');
    }
  }

  static String? get fcmToken => _fcmToken;
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background message received');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}
