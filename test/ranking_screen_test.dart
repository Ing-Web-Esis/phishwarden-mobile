import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phishwarden_movil/features/ranking/data/ranking_repository.dart';
import 'package:phishwarden_movil/features/ranking/presentation/ranking_screen.dart';

class _FakeRankingRepository implements RankingRepository {
  @override
  Future<RankingData> load() async => const RankingData(
    myPosition: 2,
    entries: [
      RankingEntry(
        position: 1,
        name: 'Ana Lopez',
        department: 'Finanzas',
        points: 120,
        medalsCount: 3,
        safeDays: 8,
        isCurrentUser: false,
      ),
      RankingEntry(
        position: 2,
        name: 'David Montoya',
        department: 'TI',
        points: 40,
        medalsCount: 2,
        safeDays: 0,
        isCurrentUser: true,
      ),
    ],
  );
}

void main() {
  testWidgets('muestra la posición del usuario y la lista del ranking', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RankingScreen(
          repository: _FakeRankingRepository(),
          onProfile: () {},
          onTraining: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Puesto 2 de 2'), findsOneWidget);
    expect(find.text('40 puntos de aprendizaje'), findsOneWidget);
    expect(find.text('Ana Lopez'), findsOneWidget);
    expect(find.text('David Montoya · Tú'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  test('formatPoints separa miles con punto', () {
    expect(formatPoints(950), '950');
    expect(formatPoints(1250), '1.250');
    expect(formatPoints(1120000), '1.120.000');
  });
}
