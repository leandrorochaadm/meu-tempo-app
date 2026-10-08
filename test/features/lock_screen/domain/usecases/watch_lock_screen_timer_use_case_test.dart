import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/appointment/domain/entities/appointment_entity.dart';
import 'package:meu_tempo/features/appointment/domain/repositories/appointment_repository.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/repositories/task_list_repository.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_timer_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/watch_lock_screen_timer_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/active_timer_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/repositories/timer_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockTimerRepo extends Mock implements TimerRepository {}

class _MockTaskRepo extends Mock implements TaskRepository {}

class _MockAppointmentRepo extends Mock implements AppointmentRepository {}

class _MockTaskListRepo extends Mock implements TaskListRepository {}

typedef _Result = Either<Failure, LockScreenTimerEntity?>;

void main() {
  late _MockTimerRepo timerRepo;
  late _MockTaskRepo taskRepo;
  late _MockAppointmentRepo apptRepo;
  late _MockTaskListRepo listRepo;
  late StreamController<Either<Failure, ActiveTimerEntity?>> timerCtrl;
  late StreamController<Either<Failure, List<TaskEntity>>> tasksCtrl;
  late StreamController<Either<Failure, List<AppointmentEntity>>> apptsCtrl;
  late StreamController<Either<Failure, List<TaskListEntity>>> listsCtrl;
  late WatchLockScreenTimerUseCase useCase;

  final start = DateTime(2026, 10, 7, 10);
  const work = TaskListEntity(id: 'work', name: 'Trabalho');
  const personal = TaskListEntity(id: 'personal', name: 'Pessoal');
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

  Right<Failure, ActiveTimerEntity?> activeTask({
    TimerStatusEnum status = TimerStatusEnum.running,
  }) => Right(
    ActiveTimerEntity(
      targetId: 't1',
      targetType: TimerTargetTypeEnum.task,
      listId: 'work',
      startedAt: start,
      status: status,
    ),
  );

  Right<Failure, ActiveTimerEntity?> activeAppointment() => Right(
    ActiveTimerEntity(
      targetId: 'a1',
      targetType: TimerTargetTypeEnum.appointment,
      listId: 'personal',
      startedAt: start,
    ),
  );

  LockScreenTimerEntity taskEntity({
    int spent = 40,
    TimerStatusEnum status = TimerStatusEnum.running,
    String listName = 'Trabalho',
  }) => LockScreenTimerEntity(
    targetId: 't1',
    targetType: TimerTargetTypeEnum.task,
    title: 'Tela de login',
    listName: listName,
    status: status,
    spentMinutes: spent,
    sessionStartedAt: start,
  );

  LockScreenTimerEntity appointmentEntity() => LockScreenTimerEntity(
    targetId: 'a1',
    targetType: TimerTargetTypeEnum.appointment,
    title: 'Dentista',
    listName: 'Pessoal',
    status: TimerStatusEnum.running,
    spentMinutes: 10,
    sessionStartedAt: start,
  );

  void wire({void Function()? onCancel}) {
    timerCtrl = StreamController.broadcast(onCancel: onCancel);
    tasksCtrl = StreamController.broadcast(onCancel: onCancel);
    apptsCtrl = StreamController.broadcast(onCancel: onCancel);
    listsCtrl = StreamController.broadcast(onCancel: onCancel);
  }

  setUp(() {
    timerRepo = _MockTimerRepo();
    taskRepo = _MockTaskRepo();
    apptRepo = _MockAppointmentRepo();
    listRepo = _MockTaskListRepo();
    wire();
    when(() => timerRepo.watchActive()).thenAnswer((_) => timerCtrl.stream);
    when(
      () => taskRepo.watchTasks(includeDone: true),
    ).thenAnswer((_) => tasksCtrl.stream);
    when(() => apptRepo.watchAll()).thenAnswer((_) => apptsCtrl.stream);
    when(() => listRepo.watchLists()).thenAnswer((_) => listsCtrl.stream);
    useCase = WatchLockScreenTimerUseCase(
      timerRepo,
      taskRepo,
      apptRepo,
      listRepo,
    );
  });

  tearDown(() async {
    await timerCtrl.close();
    await tasksCtrl.close();
    await apptsCtrl.close();
    await listsCtrl.close();
  });

  test('sem cronômetro emite null sem esperar os outros fluxos', () async {
    final expectation = expectLater(
      useCase(const NoParams()),
      emitsInOrder([const Right<Failure, LockScreenTimerEntity?>(null)]),
    );
    timerCtrl.add(const Right(null));
    await expectation;
  });

  test('tarefa rodando: emite depois de tarefas e listas', () async {
    final expectation = expectLater(
      useCase(const NoParams()),
      emitsInOrder([Right<Failure, LockScreenTimerEntity?>(taskEntity())]),
    );
    timerCtrl.add(activeTask());
    listsCtrl.add(const Right([work, personal]));
    tasksCtrl.add(Right([task]));
    await expectation;
  });

  test('compromisso rodando: usa compromissos e listas', () async {
    final expectation = expectLater(
      useCase(const NoParams()),
      emitsInOrder([
        Right<Failure, LockScreenTimerEntity?>(appointmentEntity()),
      ]),
    );
    timerCtrl.add(activeAppointment());
    listsCtrl.add(const Right([work, personal]));
    apptsCtrl.add(Right([appointment]));
    await expectation;
  });

  test('pausar: status muda e depois o tempo já gasto é atualizado', () async {
    final expectation = expectLater(
      useCase(const NoParams()),
      emitsInOrder([
        Right<Failure, LockScreenTimerEntity?>(taskEntity()),
        Right<Failure, LockScreenTimerEntity?>(
          taskEntity(status: TimerStatusEnum.paused),
        ),
        Right<Failure, LockScreenTimerEntity?>(
          taskEntity(status: TimerStatusEnum.paused, spent: 65),
        ),
      ]),
    );
    timerCtrl.add(activeTask());
    listsCtrl.add(const Right([work, personal]));
    tasksCtrl.add(Right([task]));
    await Future<void>.delayed(Duration.zero);
    timerCtrl.add(activeTask(status: TimerStatusEnum.paused));
    await Future<void>.delayed(Duration.zero);
    tasksCtrl.add(
      Right([
        TaskEntity(
          id: 't1',
          title: 'Tela de login',
          listId: 'work',
          createdAt: DateTime(2026, 10, 1),
          spentMinutes: 65,
        ),
      ]),
    );
    await expectation;
  });

  test('start em outro alvo troca o que aparece', () async {
    final expectation = expectLater(
      useCase(const NoParams()),
      emitsInOrder([
        Right<Failure, LockScreenTimerEntity?>(taskEntity()),
        const Right<Failure, LockScreenTimerEntity?>(null),
        Right<Failure, LockScreenTimerEntity?>(appointmentEntity()),
      ]),
    );
    listsCtrl.add(const Right([work, personal]));
    tasksCtrl.add(Right([task]));
    apptsCtrl.add(Right([appointment]));
    timerCtrl.add(activeTask());
    await Future<void>.delayed(Duration.zero);
    timerCtrl.add(const Right(null));
    await Future<void>.delayed(Duration.zero);
    timerCtrl.add(activeAppointment());
    await expectation;
  });

  test('cronômetro some (parar): emite null', () async {
    final expectation = expectLater(
      useCase(const NoParams()),
      emitsInOrder([
        Right<Failure, LockScreenTimerEntity?>(taskEntity()),
        const Right<Failure, LockScreenTimerEntity?>(null),
      ]),
    );
    timerCtrl.add(activeTask());
    listsCtrl.add(const Right([work]));
    tasksCtrl.add(Right([task]));
    await Future<void>.delayed(Duration.zero);
    timerCtrl.add(const Right(null));
    await expectation;
  });

  test('mudança em outra tarefa não repete a emissão', () async {
    final emitted = <_Result>[];
    final sub = useCase(const NoParams()).listen(emitted.add);
    timerCtrl.add(activeTask());
    listsCtrl.add(const Right([work]));
    tasksCtrl.add(Right([task]));
    await Future<void>.delayed(Duration.zero);
    tasksCtrl.add(
      Right([
        task,
        TaskEntity(
          id: 't2',
          title: 'Outra',
          listId: 'work',
          createdAt: DateTime(2026, 10, 2),
        ),
      ]),
    );
    await Future<void>.delayed(Duration.zero);

    expect(emitted, hasLength(1));
    await sub.cancel();
  });

  test('renomear a lista atualiza o nome', () async {
    final expectation = expectLater(
      useCase(const NoParams()),
      emitsInOrder([
        Right<Failure, LockScreenTimerEntity?>(taskEntity()),
        Right<Failure, LockScreenTimerEntity?>(taskEntity(listName: 'Serviço')),
      ]),
    );
    timerCtrl.add(activeTask());
    listsCtrl.add(const Right([work]));
    tasksCtrl.add(Right([task]));
    await Future<void>.delayed(Duration.zero);
    listsCtrl.add(const Right([TaskListEntity(id: 'work', name: 'Serviço')]));
    await expectation;
  });

  test('alvo não encontrado emite null', () async {
    final expectation = expectLater(
      useCase(const NoParams()),
      emitsInOrder([const Right<Failure, LockScreenTimerEntity?>(null)]),
    );
    timerCtrl.add(activeTask());
    listsCtrl.add(const Right([work]));
    tasksCtrl.add(const Right([]));
    await expectation;
  });

  test('falha no cronômetro emite Left', () async {
    final expectation = expectLater(
      useCase(const NoParams()),
      emitsInOrder([
        const Left<Failure, LockScreenTimerEntity?>(NetworkFailure()),
      ]),
    );
    timerCtrl.add(const Left(NetworkFailure()));
    await expectation;
  });

  test('falha nas tarefas com alvo tarefa emite Left', () async {
    final expectation = expectLater(
      useCase(const NoParams()),
      emitsInOrder([
        const Left<Failure, LockScreenTimerEntity?>(ServerFailure()),
      ]),
    );
    timerCtrl.add(activeTask());
    listsCtrl.add(const Right([work]));
    tasksCtrl.add(const Left(ServerFailure()));
    await expectation;
  });

  test('falha nos compromissos é ignorada quando o alvo é tarefa', () async {
    final expectation = expectLater(
      useCase(const NoParams()),
      emitsInOrder([Right<Failure, LockScreenTimerEntity?>(taskEntity())]),
    );
    apptsCtrl.add(const Left(ServerFailure()));
    timerCtrl.add(activeTask());
    listsCtrl.add(const Right([work]));
    tasksCtrl.add(Right([task]));
    await expectation;
  });

  test('falha nas listas emite Left', () async {
    final expectation = expectLater(
      useCase(const NoParams()),
      emitsInOrder([
        const Left<Failure, LockScreenTimerEntity?>(ServerFailure()),
      ]),
    );
    timerCtrl.add(activeTask());
    listsCtrl.add(const Left(ServerFailure()));
    await expectation;
  });

  test('pede as tarefas com as concluídas', () async {
    final sub = useCase(const NoParams()).listen((_) {});
    await Future<void>.delayed(Duration.zero);

    verify(() => taskRepo.watchTasks(includeDone: true)).called(1);
    await sub.cancel();
  });

  test('cancelar a assinatura cancela os quatro fluxos', () async {
    await timerCtrl.close();
    await tasksCtrl.close();
    await apptsCtrl.close();
    await listsCtrl.close();
    var cancelled = 0;
    wire(onCancel: () => cancelled++);

    final sub = useCase(const NoParams()).listen((_) {});
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(cancelled, 4);
  });
}
