import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/appointment/domain/entities/appointment_entity.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/services/lock_screen_timer_resolver.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

void main() {
  const lists = [
    TaskListEntity(id: 'work', name: 'Trabalho'),
    TaskListEntity(id: 'personal', name: 'Pessoal'),
  ];
  final start = DateTime(2026, 10, 7, 10);
  final task = TaskEntity(
    id: 't1',
    title: 'Tela de login',
    listId: 'work',
    createdAt: DateTime(2026, 10, 1),
    spentMinutes: 40,
  );
  final appointment = AppointmentEntity(
    id: 'a1',
    title: 'Dentista',
    listId: 'personal',
    date: DateTime(2026, 10, 7),
    startMinute: 900,
    durationMinutes: 60,
    spentMinutes: 10,
  );

  ActiveTimerEntity active(
    String id,
    TimerTargetTypeEnum type, {
    String listId = 'work',
    TimerStatusEnum status = TimerStatusEnum.running,
  }) =>
      ActiveTimerEntity(
        targetId: id,
        targetType: type,
        listId: listId,
        startedAt: start,
        status: status,
      );

  test('tarefa: nome, lista e tempo já gasto', () {
    final result = LockScreenTimerResolver.fromTask(
      active('t1', TimerTargetTypeEnum.task),
      [task],
      lists,
    )!;
    expect(result.title, 'Tela de login');
    expect(result.listName, 'Trabalho');
    expect(result.spentMinutes, 40);
    expect(result.targetType, TimerTargetTypeEnum.task);
    expect(result.status, TimerStatusEnum.running);
    expect(result.sessionStartedAt, start);
  });

  test('compromisso: nome, lista e tempo já gasto', () {
    final result = LockScreenTimerResolver.fromAppointment(
      active('a1', TimerTargetTypeEnum.appointment, listId: 'personal'),
      [appointment],
      lists,
    )!;
    expect(result.title, 'Dentista');
    expect(result.listName, 'Pessoal');
    expect(result.spentMinutes, 10);
    expect(result.targetType, TimerTargetTypeEnum.appointment);
  });

  test('pausado repassa o status', () {
    final result = LockScreenTimerResolver.fromTask(
      active('t1', TimerTargetTypeEnum.task, status: TimerStatusEnum.paused),
      [task],
      lists,
    )!;
    expect(result.isPaused, isTrue);
  });

  test('lista vem do alvo, não do cronômetro', () {
    final result = LockScreenTimerResolver.fromTask(
      active('t1', TimerTargetTypeEnum.task, listId: 'old'),
      [task],
      lists,
    )!;
    expect(result.listName, 'Trabalho');
  });

  test('lista não encontrada vira nome vazio', () {
    final result = LockScreenTimerResolver.fromTask(
      active('t1', TimerTargetTypeEnum.task),
      [task],
      const [],
    )!;
    expect(result.listName, '');
  });

  test('tarefa não encontrada devolve null', () {
    expect(
      LockScreenTimerResolver.fromTask(
        active('zzz', TimerTargetTypeEnum.task),
        [task],
        lists,
      ),
      isNull,
    );
  });

  test('compromisso não encontrado devolve null', () {
    expect(
      LockScreenTimerResolver.fromAppointment(
        active('zzz', TimerTargetTypeEnum.appointment),
        [appointment],
        lists,
      ),
      isNull,
    );
  });

  test('tarefa concluída continua aparecendo', () {
    final done = TaskEntity(
      id: 't1',
      title: 'Tela de login',
      listId: 'work',
      createdAt: DateTime(2026, 10, 1),
      isDone: true,
    );
    expect(
      LockScreenTimerResolver.fromTask(
        active('t1', TimerTargetTypeEnum.task),
        [done],
        lists,
      ),
      isNotNull,
    );
  });
}
