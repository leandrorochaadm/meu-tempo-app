import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../../../core/utils/formatters/date_formatter.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../bloc/migration_bloc.dart';

/// Tela de migração das pendências (folhas não concluídas de dias anteriores).
class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key});

  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  @override
  void initState() {
    super.initState();
    context.read<MigrationBloc>().add(const MigrationStarted());
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Pendências de ontem')),
      body: SafeArea(
        top: false,
        child: BlocBuilder<MigrationBloc, MigrationState>(
          builder: (context, state) {
            return switch (state) {
              MigrationLoading() => const AppListSkeleton(),
              MigrationError() => const AppEmptyState(
                  icon: Icons.history_rounded,
                  title: 'Não foi possível carregar',
                  message: 'Tente novamente em instantes.',
                ),
              MigrationLoaded(:final pending) => pending.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.check_circle_rounded,
                      title: 'Nada a migrar',
                      message: 'Você está em dia com suas pendências.',
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(context.space.lg),
                      itemCount: pending.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: context.space.sm),
                      itemBuilder: (context, i) => _PendingTile(
                        task: pending[i],
                        today: today,
                        onMigrate: () => context
                            .read<MigrationBloc>()
                            .add(TaskMigrated(pending[i])),
                        onDiscard: () => context
                            .read<MigrationBloc>()
                            .add(TaskDiscarded(pending[i].id)),
                      ),
                    ),
            };
          },
        ),
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({
    required this.task,
    required this.today,
    required this.onMigrate,
    required this.onDiscard,
  });

  final TaskEntity task;
  final DateTime today;
  final VoidCallback onMigrate;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(context.space.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.radius.lgRadius,
        border: Border(left: BorderSide(color: colors.warning, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.title, style: context.text.titleMedium),
          SizedBox(height: context.space.xs),
          Text(
            'Vencia em ${DateFormatter.relativeLabel(task.dueDate ?? today, today)}',
            style: context.text.labelSmall,
          ),
          SizedBox(height: context.space.md),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: onMigrate,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Migrar p/ hoje'),
              ),
              SizedBox(width: context.space.sm),
              OutlinedButton.icon(
                onPressed: onDiscard,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Descartar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
