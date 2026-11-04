import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/theme/app_theme.dart';
import 'package:gymflow/models/history.dart';
import 'package:gymflow/models/labels.dart';
import 'package:gymflow/state/progress_cubit.dart';
import 'package:gymflow/ui/features/progress/consistency_calendar.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  Future<void> pumpCalendar(
    WidgetTester tester,
    List<LogEntry> logs, {
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConsistencyCalendar(ProgressState(logs: logs)),
          ),
        ),
      ),
    );
  }

  testWidgets('mostra o mês e abre os treinos do dia tocado', (tester) async {
    await pumpCalendar(tester, [LogEntry(today, 'Treino A', 5, 45)]);

    expect(
      find.text('${monthNames[today.month - 1]} ${today.year}'.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('Treino A'), findsNothing);

    await tester.tap(find.text('${today.day}').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Treino A'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);

    await tester.tap(find.text('${today.day}').last); // toca de novo: fecha
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Treino A'), findsNothing);
  });

  testWidgets('navega entre meses só até o primeiro treino', (tester) async {
    final old = today.subtract(const Duration(days: 40));
    await pumpCalendar(tester, [
      LogEntry(today, 'Treino A', 5, 45),
      LogEntry(old, 'Treino B', 4, 30),
    ]);

    IconButton button(String tooltip) => tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, _icon(tooltip)),
    );
    expect(button('Próximo mês').onPressed, isNull);

    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pump();
    final prev = DateTime(today.year, today.month - 1);
    expect(
      find.text('${monthNames[prev.month - 1]} ${prev.year}'.toUpperCase()),
      findsOneWidget,
    );
    expect(button('Próximo mês').onPressed, isNotNull);
  });

  testWidgets('sem sobra de layout em tela estreita', (tester) async {
    await pumpCalendar(tester, [
      for (var i = 0; i < 6; i++)
        LogEntry(today.subtract(Duration(days: i)), 'Treino', 5, 40),
    ], width: 320);
    expect(tester.takeException(), isNull);
  });
}

IconData _icon(String tooltip) => tooltip == 'Próximo mês'
    ? Icons.chevron_right_rounded
    : Icons.chevron_left_rounded;
