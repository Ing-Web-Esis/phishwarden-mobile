import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = NotificationService();
  try {
    await notifications.initialize();
  } catch (error) {
    // Mantiene la bienvenida disponible; el botón permite reintentar.
    debugPrint('No se pudo inicializar notificaciones: $error');
  }
  runApp(PhishWardenApp(notifications: notifications));
}
