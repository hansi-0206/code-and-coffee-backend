import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // 🔥 prevents multiple init calls
  static bool _initialized = false;

  /* =========================================================
     INITIALIZE
  ========================================================= */
  static Future<void> init() async {

    if (_initialized) return;

    // ---------- ANDROID ----------
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // ---------- IOS ----------
    const DarwinInitializationSettings iosInit =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings =
        InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        );

    await _plugin.initialize(settings);

    // 🔥 Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'order_updates',
      'Order Updates',
      description: 'Notifications for order status updates',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 🔥 Android 13+ permission
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } on PlatformException {}

    _initialized = true;
  }

  /* =========================================================
     SHOW NOTIFICATION
  ========================================================= */
  static Future<void> show({
    required String title,
    required String body,
  }) async {

    if (!_initialized) {
      await init();
    }

    final int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'order_updates',
      'Order Updates',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      notificationId,
      title,
      body,
      details,
    );
  }

  /* =========================================================
     CANCEL ALL
  ========================================================= */
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
