import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/task_list_bloc.dart';
import '../widgets/quick_add_task_widget.dart';
import '../widgets/task_card_widget.dart';

/// Listagem de tarefas + criação rápida (barra no topo).
class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  bool _quickAddVisible = false;

  @override
  void initState() {
    super.initState();
    context.read<TaskListBloc>().add(const TaskListStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Tempo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Input SEMPRE no topo — o teclado (que sobe de baixo) não o cobre.
            if (_quickAddVisible)
              QuickAddTaskWidget(
                onSubmit: (title) =>
                    context.read<TaskListBloc>().add(TaskCreated(title)),
              ),
            Expanded(
              child: BlocConsumer<TaskListBloc, TaskListState>(
                listenWhen: (_, curr) => curr is TaskListError,
                listener: (context, state) {
                  if (state is TaskListError) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) {
                  return switch (state) {
                    TaskListLoading() => const AppListSkeleton(),
                    TaskListEmpty() => const AppEmptyState(
                        icon: Icons.checklist_rounded,
                        title: 'Sua lista está vazia',
                        message: 'Toque em + para criar sua primeira tarefa.',
                      ),
                    TaskListLoaded(:final tasks) => ListView.separated(
                        padding: EdgeInsets.all(context.space.lg),
                        itemCount: tasks.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: context.space.md),
                        itemBuilder: (context, i) =>
                            TaskCardWidget(task: tasks[i]),
                      ),
                    // Erro é mostrado via snackbar; mantém a última lista/vazio.
                    TaskListError() => const AppEmptyState(
                        icon: Icons.checklist_rounded,
                        title: 'Sua lista está vazia',
                        message: 'Toque em + para criar sua primeira tarefa.',
                      ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _quickAddVisible = !_quickAddVisible),
        child: Icon(_quickAddVisible ? Icons.close_rounded : Icons.add_rounded),
      ),
    );
  }
}
