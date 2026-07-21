import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/appointment/domain/entities/appointment_entity.dart';
import 'package:meu_tempo/features/report/domain/entities/report_tree_node.dart';
import 'package:meu_tempo/features/report/domain/entities/task_report_sort_enum.dart';
import 'package:meu_tempo/features/report/domain/usecases/get_task_report_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

void main() {
  const useCase = GetTaskReportUseCase();
  final today = DateTime(2026, 7, 20);

  TaskEntity leaf(
    String id,
    String listId,
    int est, {
    String? parentId,
    String? title,
  }) =>
      TaskEntity(
        id: id,
        title: title ?? id,
        listId: listId,
        createdAt: today,
        estimatedMinutes: est,
        parentId: parentId,
      );

  TaskEntity mother(String id, String listId, {String? parentId}) => TaskEntity(
        id: id,
        title: id,
        listId: listId,
        createdAt: today,
        parentId: parentId,
        hasChildren: true,
      );

  TimeEntryEntity entry(
    String targetId,
    String listId,
    int minutes, {
    TimerTargetTypeEnum type = TimerTargetTypeEnum.task,
  }) =>
      TimeEntryEntity(
        id: '$targetId-$minutes',
        targetId: targetId,
        targetType: type,
        listId: listId,
        minutes: minutes,
        origin: TimeEntryOriginEnum.timer,
        occurredAt: today,
      );

  AppointmentEntity appt(String id, String listId, String title) =>
      AppointmentEntity(
        id: id,
        title: title,
        listId: listId,
        date: today,
        startMinute: 900,
        durationMinutes: 60,
      );

  ReportTreeNode nodeById(TaskReport r, String id) =>
      r.nodes.firstWhere((n) => n.id == id);

  test('folha de topo (sem mãe): vira nó raiz com gasto e estouro', () {
    final r = useCase(
      [entry('a', 'prof', 30), entry('a', 'prof', 20)],
      [leaf('a', 'prof', 60)],
      const [],
      'prof',
      TaskReportSortEnum.spent,
    );
    expect(r.nodes.length, 1);
    final a = r.nodes.single;
    expect(a.spentMinutes, 50);
    expect(a.estimatedMinutes, 60);
    expect(a.overrunMinutes, -10);
    expect(a.isLeaf, isTrue);
    expect(r.totalSpentMinutes, 50);
    expect(r.totalEstimatedMinutes, 60);
  });

  test('monta a hierarquia mãe→filha e agrega gasto/estimado para cima', () {
    final r = useCase(
      [entry('f1', 'prof', 90), entry('f2', 'prof', 30)],
      [
        mother('mae', 'prof'),
        leaf('f1', 'prof', 60, parentId: 'mae'),
        leaf('f2', 'prof', 45, parentId: 'mae'),
      ],
      const [],
      'prof',
      TaskReportSortEnum.spent,
    );

    expect(r.nodes.length, 1); // só a raiz (mãe)
    final mae = r.nodes.single;
    expect(mae.id, 'mae');
    expect(mae.isLeaf, isFalse);
    expect(mae.spentMinutes, 120); // 90 + 30
    expect(mae.estimatedMinutes, 105); // 60 + 45 (folhas)
    expect(mae.children.map((c) => c.id), containsAll(['f1', 'f2']));
    // filha sem tempo no período não entra.
  });

  test('folha sem tempo não aparece na árvore', () {
    final r = useCase(
      [entry('f1', 'prof', 90)],
      [
        mother('mae', 'prof'),
        leaf('f1', 'prof', 60, parentId: 'mae'),
        leaf('f2', 'prof', 45, parentId: 'mae'), // sem entry
      ],
      const [],
      'prof',
      TaskReportSortEnum.spent,
    );
    final mae = r.nodes.single;
    expect(mae.children.map((c) => c.id), ['f1']);
  });

  test('tarefa que virou mãe mantém seu tempo próprio agregado', () {
    // "mae" teve 5min quando era folha (entry direto nela) + filha f1 90min.
    final r = useCase(
      [entry('mae', 'prof', 5), entry('f1', 'prof', 90)],
      [mother('mae', 'prof'), leaf('f1', 'prof', 60, parentId: 'mae')],
      const [],
      'prof',
      TaskReportSortEnum.spent,
    );
    final mae = r.nodes.single;
    expect(mae.spentMinutes, 95); // 5 próprio + 90 da filha
    expect(r.totalSpentMinutes, 95);
  });

  test('3 níveis (avó→mãe→neta): agrega subindo e poda ramo sem tempo', () {
    final r = useCase(
      [entry('neta_a', 'prof', 40)], // só neta_a tem tempo
      [
        mother('avo', 'prof'),
        mother('mae', 'prof', parentId: 'avo'),
        leaf('neta_a', 'prof', 30, parentId: 'mae'),
        leaf('neta_b', 'prof', 15, parentId: 'mae'), // sem tempo → podada
        mother('mae2', 'prof', parentId: 'avo'), // ramo sem tempo → podado
      ],
      const [],
      'prof',
      TaskReportSortEnum.spent,
    );

    expect(r.nodes.length, 1);
    final avo = r.nodes.single;
    expect(avo.id, 'avo');
    expect(avo.level, 0);
    expect(avo.spentMinutes, 40);
    expect(avo.estimatedMinutes, 30); // só neta_a (folha com tempo)
    expect(avo.children.map((c) => c.id), ['mae']); // mae2 podada

    final mae = avo.children.single;
    expect(mae.level, 1);
    expect(mae.children.map((c) => c.id), ['neta_a']); // neta_b podada

    final neta = mae.children.single;
    expect(neta.level, 2);
    expect(neta.isLeaf, isTrue);
    expect(neta.spentMinutes, 40);
    expect(neta.overrunMinutes, 10); // 40 - 30
  });

  test('compromisso entra como nó de topo, sem estimativa nem estouro', () {
    final r = useCase(
      [entry('ap1', 'prof', 40, type: TimerTargetTypeEnum.appointment)],
      const [],
      [appt('ap1', 'prof', 'Reunião semanal')],
      'prof',
      TaskReportSortEnum.spent,
    );
    final node = r.nodes.single;
    expect(node.title, 'Reunião semanal');
    expect(node.targetType, TimerTargetTypeEnum.appointment);
    expect(node.estimatedMinutes, isNull);
    expect(node.overrunMinutes, isNull);
    expect(r.totalEstimatedMinutes, 0);
  });

  test('filtra pela lista pedida', () {
    final r = useCase(
      [entry('a', 'prof', 30), entry('z', 'estudo', 99)],
      [leaf('a', 'prof', 60), leaf('z', 'estudo', 10)],
      const [],
      'prof',
      TaskReportSortEnum.spent,
    );
    expect(r.nodes.map((n) => n.id), ['a']);
  });

  test('ordena o topo por tempo gasto desc', () {
    final r = useCase(
      [entry('a', 'x', 10), entry('b', 'x', 100)],
      [leaf('a', 'x', 10), leaf('b', 'x', 10)],
      const [],
      'x',
      TaskReportSortEnum.spent,
    );
    expect(r.nodes.first.id, 'b');
  });

  test('ordena por estouro; compromisso (sem estouro) vai ao fim', () {
    final r = useCase(
      [
        entry('a', 'x', 300), // est 60 → +240
        entry('b', 'x', 70), // est 60 → +10
        entry('ap', 'x', 999, type: TimerTargetTypeEnum.appointment),
      ],
      [leaf('a', 'x', 60), leaf('b', 'x', 60)],
      [appt('ap', 'x', 'Compromisso')],
      'x',
      TaskReportSortEnum.overrun,
    );
    expect(r.nodes.map((n) => n.id).toList(), ['a', 'b', 'ap']);
    expect(nodeById(r, 'a').overrunMinutes, 240);
  });
}
