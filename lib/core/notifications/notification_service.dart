import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Adaptador al sistema operativo. No autentica ni recibe mensajes del servidor.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  final pendingLesson = ValueNotifier<String?>(null);
  bool _initialized = false;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final id = response.payload;
        if (id != null && id.isNotEmpty) pendingLesson.value = id;
      },
    );
    // El callback anterior no cubre un arranque con la app terminada.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      pendingLesson.value = launch?.notificationResponse?.payload;
    }
    _initialized = true;
  }

  Future<bool> showLessonNotification(String lessonId) async {
    if (!isSupported) throw UnsupportedError('Esta prueba requiere Android.');
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;
    final granted = await android.requestNotificationsPermission();
    if (granted == false || await android.areNotificationsEnabled() == false) {
      return false;
    }
    await _plugin.show(
      id: 2,
      title: 'Tu microlección está lista',
      body: 'Reconoce un correo de phishing. Toca para aprender.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'microlearning',
          'Microlecciones',
          channelDescription: 'Avisos para iniciar un entrenamiento breve',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: lessonId,
    );
    return true;
  }
}
