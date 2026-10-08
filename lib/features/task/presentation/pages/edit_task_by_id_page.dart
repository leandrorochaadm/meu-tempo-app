import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../domain/entities/task_edit_target_entity.dart';
import '../bloc/active_timer_bloc.dart';
import '../bloc/edit_task_by_id_bloc.dart';
import 'edit_task_args.dart';
import 'edit_task_page.dart';

/// Opens the edit screen of a task by id only — destination of the tap on the
/// lock screen timer (`Routes.timerTarget`). Loads the context, pushes the
/// usual edit form (`Routes.editTask`) and, when the user comes back, closes
/// itself. The save goes through the same path as the timer bar
/// (`ActiveTimerEditSubmitted` on the global `ActiveTimerBloc`), which also
/// shows the failure in the bar's snackbar.
class EditTaskByIdPage extends StatefulWidget {
  const EditTaskByIdPage({super.key, required this.taskId});

  final String taskId;

  @override
  State<EditTaskByIdPage> createState() => _EditTaskByIdPageState();
}

class _EditTaskByIdPageState extends State<EditTaskByIdPage> {
  /// Guarantees a single opening of the form.
  bool _editorOpened = false;

  @override
  void initState() {
    super.initState();
    context.read<EditTaskByIdBloc>().add(EditTaskByIdStarted(widget.taskId));
  }

  Future<void> _openEditor(TaskEditTargetEntity target) async {
    if (_editorOpened) return;
    _editorOpened = true;
    final timerBloc = context.read<ActiveTimerBloc>();
    final args = EditTaskArgs.fromContext(target.editContext, target.lists);
    final result = await context.push<EditTaskResult>(
      Routes.editTask,
      extra: args,
    );
    if (result != null) {
      timerBloc.add(ActiveTimerEditSubmitted(widget.taskId, result));
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar tarefa')),
      body: SafeArea(
        top: false,
        child: BlocConsumer<EditTaskByIdBloc, EditTaskByIdState>(
          listenWhen: (_, curr) => curr is EditTaskByIdReady,
          listener: (_, state) {
            if (state is EditTaskByIdReady) _openEditor(state.target);
          },
          builder: (_, state) => switch (state) {
            EditTaskByIdLoading() ||
            EditTaskByIdReady() =>
              const AppListSkeleton(),
            EditTaskByIdNotFound() => const AppEmptyState(
                icon: Icons.search_off_rounded,
                title: 'Tarefa não encontrada',
                message: 'Ela pode ter sido apagada.',
              ),
            EditTaskByIdError(:final message) => AppEmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Não deu para abrir a tarefa',
                message: message,
              ),
          },
        ),
      ),
    );
  }
}
