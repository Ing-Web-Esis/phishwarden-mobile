import 'package:flutter/foundation.dart';

import '../../../core/notifications/notification_service.dart';
import '../data/lesson_repository.dart';

class NotificationPracticeViewModel extends ChangeNotifier {
  NotificationPracticeViewModel(this._service);
  final NotificationService _service;
  bool isLoading = false;
  String? message;
  bool _disposed = false;
  bool get isSupported => _service.isSupported;

  Future<void> send() async {
    if (isLoading || _disposed) return;
    isLoading = true;
    message = null;
    notifyListeners();
    try {
      final sent = await _service.showLessonNotification(
        LocalLessonRepository.practiceLessonId,
      );
      message = sent
          ? 'Se solicitó mostrar la notificación. Abre la bandeja de Android y tócala.'
          : 'Notificaciones desactivadas. Actívalas en Ajustes > Aplicaciones > PhishWarden MJ > Notificaciones y vuelve a intentarlo.';
    } catch (_) {
      message = 'No se pudo mostrar la notificación. Comprueba Android y la configuración del proyecto y reintenta.';
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
