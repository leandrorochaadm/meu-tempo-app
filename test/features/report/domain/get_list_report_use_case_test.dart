import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/report/domain/usecases/get_list_report_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

void main() {
  const useCase = GetListReportUseCase();
  final today = DateTime(2026, 7, 20);

  TaskEntity leaf(String id, String listId, int est,
          {bool hasChildren = false}) =>
      TaskEntity(
        id: id,
        title: id,
        listId: listId,
        createdAt: today,
        estimatedMinutes: est,
        hasChildren: hasChildren,
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

  test('real = soma das entries; estimado só das folhas que tiveram tempo', () {
    final report = useCase(
      [
        entry('a', 'prof', 90),
        entry('c', 'estudo', 45),
      ],
      [
        leaf('a', 'prof', 60),
        leaf('b', 'prof', 30), // sem entry → não conta no estimado
        leaf('mae', 'prof', 0, hasChildren: true),
        leaf('c', 'estudo', 120),
      ],
      const [
        TaskListEntity(id: 'prof', name: 'Profissional'),
        TaskListEntity(id: 'estudo', name: 'Estudo'),
      ],
    );

    final prof = report.rows.firstWhere((r) => r.listId == 'prof');
    expect(prof.listName, 'Profissional');
    expect(prof.spentMinutes, 90);
    expect(prof.estimatedMinutes, 60); // só 'a' teve tempo (b excluído)
    final estudo = report.rows.firstWhere((r) => r.listId == 'estudo');
    expect(estudo.spentMinutes, 45);
    expect(estudo.estimatedMinutes, 120);
  });

  test('tempo de compromisso entra no real, mas não no estimado', () {
    final report = useCase(
      [entry('appt1', 'prof', 50, type: TimerTargetTypeEnum.appointment)],
      const <TaskEntity>[],
      const [TaskListEntity(id: 'prof', name: 'Profissional')],
    );
    final prof = report.rows.firstWhere((r) => r.listId == 'prof');
    expect(prof.spentMinutes, 50);
    expect(prof.estimatedMinutes, 0);
  });

  test('ordena por tempo real desc', () {
    final report = useCase(
      [entry('a', 'x', 10), entry('b', 'y', 100)],
      [leaf('a', 'x', 10), leaf('b', 'y', 10)],
      const [
        TaskListEntity(id: 'x', name: 'X'),
        TaskListEntity(id: 'y', name: 'Y'),
      ],
    );
    expect(report.rows.first.listId, 'y');
  });

  test('totais somam real e estimado de todas as listas do período', () {
    final report = useCase(
      [entry('a', 'prof', 90), entry('c', 'estudo', 45)],
      [leaf('a', 'prof', 60), leaf('c', 'estudo', 120)],
      const [
        TaskListEntity(id: 'prof', name: 'Profissional'),
        TaskListEntity(id: 'estudo', name: 'Estudo'),
      ],
    );
    expect(report.totalSpentMinutes, 135); // 90 + 45
    expect(report.totalEstimatedMinutes, 180); // 60 + 120
  });
}
