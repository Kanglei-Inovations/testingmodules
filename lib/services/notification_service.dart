import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        if (details.payload != null) {
          // Navigate if needed
        }
      },
    );

    // Create Notification Channel for Android
    const androidChannel = AndroidNotificationChannel(
      'neural_link_channel',
      'Neural Link Notifications',
      description: 'Notifications for incoming calls and messages',
      importance: Importance.max,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> showCallNotification(String callerName, bool isVideo) async {
    final title = isVideo ? "INCOMING VIDEO CALL" : "INCOMING VOICE CALL";
    final body = "$callerName is requesting a neural link...";

    const androidDetails = AndroidNotificationDetails(
      'neural_link_channel',
      'Neural Link Notifications',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      groupKey: 'calls',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notifications.show(100, title, body, notificationDetails, payload: 'call');
  }

  Future<void> showMessageNotification(String senderName, String message) async {
    const androidDetails = AndroidNotificationDetails(
      'neural_link_channel',
      'Neural Link Notifications',
      importance: Importance.max,
      priority: Priority.high,
      groupKey: 'messages',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, 
      senderName, 
      message, 
      notificationDetails, 
      payload: 'message'
    );
  }

  Future<void> cancelCallNotification() async {
    await _notifications.cancel(100);
  }
}
