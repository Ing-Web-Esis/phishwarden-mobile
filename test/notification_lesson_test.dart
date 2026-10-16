import 'package:flutter_test/flutter_test.dart';
import 'package:phishwarden_movil/app/app.dart';
import 'package:phishwarden_movil/core/notifications/notification_service.dart';
import 'package:phishwarden_movil/features/training/data/lesson_repository.dart';
import 'package:phishwarden_movil/features/training/presentation/lesson_view_model.dart';

void main() {
  testWidgets(
    'Abre la lección desde una notificación al arrancar y durante uso',
    (tester) async {
      final service = NotificationService();
      addTearDown(service.pendingLesson.dispose);
      service.pendingLesson.value = LocalLessonRepository.practiceLessonId;
      await tester.pumpWidget(PhishWardenApp(notifications: service));
      await tester.pumpAndSettle();
      expect(find.text('Reconoce un correo de phishing'), findsOneWidget);
      expect(service.pendingLesson.value, isNull);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      service.pendingLesson.value = LocalLessonRepository.practiceLessonId;
      await tester.pumpAndSettle();
      expect(find.text('Reconoce un correo de phishing'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Verifico por un canal oficial y reporto el mensaje a TI.'),
        200,
      );
      await tester.tap(
        find.text('Verifico por un canal oficial y reporto el mensaje a TI.'),
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Comprobar respuesta'));
      await tester.tap(find.text('Comprobar respuesta'));
      await tester.pump();
      expect(find.textContaining('¡Correcto!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Un ID desconocido no abre otra lección', (tester) async {
    final service = NotificationService();
    addTearDown(service.pendingLesson.dispose);
    service.pendingLesson.value = 'desconocido';
    await tester.pumpWidget(PhishWardenApp(notifications: service));
    await tester.pumpAndSettle();
    expect(find.text('No se encontró esta microlección.'), findsOneWidget);
  });

  test(
    'La respuesta se evalúa y queda bloqueada después de comprobarla',
    () async {
      final model = LessonViewModel(LocalLessonRepository());
      addTearDown(model.dispose);
      await model.load(LocalLessonRepository.practiceLessonId);
      model.submit();
      expect(model.submitted, isFalse);
      model.select(0);
      model.submit();
      expect(model.isCorrect, isFalse);
      model.select(1);
      expect(model.selectedAnswer, 0);
    },
  );
}
