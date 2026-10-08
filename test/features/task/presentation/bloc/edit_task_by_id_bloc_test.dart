import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_edit_context.dart';
import 'package:meu_tempo/features/task/domain/entities/task_edit_target_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/task_failures.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_task_edit_target_use_case.dart';
import 'package:meu_tempo/features/task/presentation/bloc/edit_task_by_id_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetTarget extends Mock implements GetTaskEditTargetUseCase {}

void main() {
  late _MockGetTarget getTarget;

  final target = TaskEditTargetEntity(
    editContext: TaskEditContext(
      task: TaskEntity(
        id: 't1',
        title: 'Tela de login',
        listId: 'inbox',
        createdAt: DateTime(2026, 10, 7),
      ),
      parentCandidates: const [],
      currentParentLabel: '',
    ),
    lists: const [TaskListEntity(id: 'inbox', name: 'Entrada')],
  );

  setUpAll(() {
    registerFallbackValue(const GetTaskEditTargetParams(taskId: 'x'));
  });

  setUp(() => getTarget = _MockGetTarget());

  blocTest<EditTaskByIdBloc, EditTaskByIdState>(
    'found: Ready',
    build: () {
      when(() => getTarget(any())).thenAnswer((_) async => Right(target));
      return EditTaskByIdBloc(getTarget);
    },
    act: (bloc) => bloc.add(const EditTaskByIdStarted('t1')),
    expect: () => [const EditTaskByIdLoading(), EditTaskByIdReady(target)],
    verify: (_) => verify(
      () => getTarget(const GetTaskEditTargetParams(taskId: 't1')),
    ).called(1),
  );

  blocTest<EditTaskByIdBloc, EditTaskByIdState>(
    'deleted: NotFound',
    build: () {
      when(
        () => getTarget(any()),
      ).thenAnswer((_) async => const Left(TaskNotFoundFailure()));
      return EditTaskByIdBloc(getTarget);
    },
    act: (bloc) => bloc.add(const EditTaskByIdStarted('t1')),
    expect: () => [const EditTaskByIdLoading(), const EditTaskByIdNotFound()],
  );

  blocTest<EditTaskByIdBloc, EditTaskByIdState>(
    'no internet: connection message',
    build: () {
      when(
        () => getTarget(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return EditTaskByIdBloc(getTarget);
    },
    act: (bloc) => bloc.add(const EditTaskByIdStarted('t1')),
    expect: () => [
      const EditTaskByIdLoading(),
      const EditTaskByIdError('Sem conexão. Verifique a internet.'),
    ],
  );

  blocTest<EditTaskByIdBloc, EditTaskByIdState>(
    'other failure: generic message',
    build: () {
      when(
        () => getTarget(any()),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return EditTaskByIdBloc(getTarget);
    },
    act: (bloc) => bloc.add(const EditTaskByIdStarted('t1')),
    expect: () => [
      const EditTaskByIdLoading(),
      const EditTaskByIdError(
        'Não foi possível abrir a tarefa. Tente de novo.',
      ),
    ],
  );
}
