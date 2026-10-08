import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/task_edit_target_entity.dart';
import '../../domain/task_failures.dart';
import '../../domain/usecases/get_task_edit_target_use_case.dart';

part 'edit_task_by_id_event.dart';
part 'edit_task_by_id_state.dart';

/// Loads, by id, what editing a task needs (tap on the lock screen timer).
/// Only orchestrates the UseCase and translates the failure.
@injectable
class EditTaskByIdBloc extends Bloc<EditTaskByIdEvent, EditTaskByIdState> {
  EditTaskByIdBloc(this._getTarget) : super(const EditTaskByIdLoading()) {
    on<EditTaskByIdStarted>(_onStarted);
  }

  final GetTaskEditTargetUseCase _getTarget;

  Future<void> _onStarted(
    EditTaskByIdStarted event,
    Emitter<EditTaskByIdState> emit,
  ) async {
    emit(const EditTaskByIdLoading());
    final result =
        await _getTarget(GetTaskEditTargetParams(taskId: event.taskId));
    result.match(
      (failure) => emit(switch (failure) {
        TaskNotFoundFailure() => const EditTaskByIdNotFound(),
        _ => EditTaskByIdError(_mapFailure(failure)),
      }),
      (target) => emit(EditTaskByIdReady(target)),
    );
  }

  String _mapFailure(Failure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão. Verifique a internet.',
        _ => 'Não foi possível abrir a tarefa. Tente de novo.',
      };
}
