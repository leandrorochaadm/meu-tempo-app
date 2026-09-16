import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/quick_add_target_entity.dart';
import '../entities/task_entity.dart';
import '../entities/timer_target_type_enum.dart';
import '../task_failures.dart';
import 'add_subtask_use_case.dart';
import 'create_task_use_case.dart';
import 'start_timer_use_case.dart';

class CreateTaskAndStartTimerParams extends Equatable {
  const CreateTaskAndStartTimerParams({
    required this.title,
    required this.listId,
    required this.now,
    this.parent,
  });

  final String title;

  /// Lista da tarefa raiz. Ignorada quando há [parent]: filha herda a lista da mãe.
  final String listId;

  /// "Agora" injetado — `createdAt` da tarefa e início da sessão do cronômetro.
  final DateTime now;

  /// Quando informado, a tarefa nasce como filha/neta dele. O alvo carrega id,
  /// lista e nível juntos, então não há como pedir uma subtarefa sem saber em
  /// que nível ela cai (o que burlaria o limite de 3 níveis).
  final QuickAddTargetEntity? parent;

  @override
  List<Object?> get props => [title, listId, now, parent];
}

/// Cria a tarefa (raiz ou subtarefa) e **já inicia o cronômetro nela** — atalho
/// "comecei agora" da criação rápida (H12). A tarefa recém-criada é sempre folha,
/// então pode receber cronômetro; a regra de "só 1 ativo por vez" (pausar o
/// anterior e somar o tempo decorrido) continua inteira no [StartTimerUseCase].
///
/// Se a criação falhar, o cronômetro **não** é tocado: o que estava rodando
/// segue rodando. Se só o cronômetro falhar, volta [TimerNotStartedFailure] com
/// o id da tarefa — que foi criada e vai aparecer na lista.
@lazySingleton
class CreateTaskAndStartTimerUseCase
    implements UseCase<TaskEntity, CreateTaskAndStartTimerParams> {
  const CreateTaskAndStartTimerUseCase(
    this._createTask,
    this._addSubtask,
    this._startTimer,
  );

  final CreateTaskUseCase _createTask;
  final AddSubtaskUseCase _addSubtask;
  final StartTimerUseCase _startTimer;

  @override
  Future<Either<Failure, TaskEntity>> call(
    CreateTaskAndStartTimerParams params,
  ) async {
    final parent = params.parent;
    final created = parent == null
        ? await _createTask(CreateTaskParams(
            title: params.title,
            listId: params.listId,
            today: params.now,
          ))
        : await _addSubtask(AddSubtaskParams(
            parentId: parent.taskId,
            parentLevel: parent.level,
            listId: parent.listId,
            title: params.title,
            today: params.now,
          ));

    final failure = created.getLeft().toNullable();
    if (failure != null) return Left(failure);

    final task = created.getRight().toNullable()!;
    final started = await _startTimer(StartTimerParams(
      targetId: task.id,
      targetType: TimerTargetTypeEnum.task,
      targetIsLeaf: true,
      listId: task.listId,
      now: params.now,
    ));

    if (started.isLeft()) return Left(TimerNotStartedFailure(task.id));

    return Right(task);
  }
}
