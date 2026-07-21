import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/theme/app_theme.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/presentation/widgets/time_entry_tile.dart';

void main() {
  final today = DateTime(2026, 7, 21);

  TimeEntryEntity entry({
    int minutes = 30,
    TimeEntryOriginEnum origin = TimeEntryOriginEnum.manual,
    DateTime? occurredAt,
  }) =>
      TimeEntryEntity(
        id: 'e1',
        targetId: 't1',
        targetType: TimerTargetTypeEnum.task,
        listId: 'l1',
        minutes: minutes,
        origin: origin,
        occurredAt: occurredAt ?? today,
      );

  late bool editTapped;
  late bool deleteTapped;

  setUp(() {
    editTapped = false;
    deleteTapped = false;
  });

  Widget harness(TimeEntryEntity e) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TimeEntryTile(
            entry: e,
            today: today,
            onEdit: () => editTapped = true,
            onDelete: () => deleteTapped = true,
          ),
        ),
      );

  void setView(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('mostra a duração formatada', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(entry(minutes: 90)));

    expect(find.text('1h30'), findsOneWidget);
  });

  testWidgets('mostra a data relativa e a origem manual', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(entry()));

    expect(find.textContaining('Hoje'), findsOneWidget);
    expect(find.textContaining('Manual'), findsOneWidget);
  });

  testWidgets('mostra a origem cronômetro', (tester) async {
    setView(tester);
    await tester
        .pumpWidget(harness(entry(origin: TimeEntryOriginEnum.timer)));

    expect(find.textContaining('Cronômetro'), findsOneWidget);
  });

  testWidgets('tocar no corpo dispara onEdit', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(entry()));

    await tester.tap(find.text('30min'));
    await tester.pump();

    expect(editTapped, isTrue);
  });

  testWidgets('tocar na lixeira dispara onDelete', (tester) async {
    setView(tester);
    await tester.pumpWidget(harness(entry()));

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump();

    expect(deleteTapped, isTrue);
    expect(editTapped, isFalse);
  });
}
