import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/list_report_row.dart';
import '../bloc/report_bloc.dart';

/// Relatório de tempo por lista: estimado × real.
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReportBloc>().add(const ReportStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatório por lista')),
      body: SafeArea(
        top: false,
        child: BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            return switch (state) {
              ReportLoading() => const AppListSkeleton(),
              ReportError() => const AppEmptyState(
                  icon: Icons.bar_chart_rounded,
                  title: 'Não foi possível carregar',
                  message: 'Tente novamente em instantes.',
                ),
              ReportLoaded(:final rows) => rows.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.bar_chart_rounded,
                      title: 'Sem dados ainda',
                      message: 'Registre tempo nas tarefas para ver o relatório.',
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(context.space.lg),
                      itemCount: rows.length,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: context.space.md),
                      itemBuilder: (context, i) =>
                          _ReportRowTile(row: rows[i], index: i),
                    ),
            };
          },
        ),
      ),
    );
  }
}

class _ReportRowTile extends StatelessWidget {
  const _ReportRowTile({required this.row, required this.index});

  final ListReportRow row;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.categoryAt(index);
    final ratio = row.estimatedMinutes == 0
        ? 0.0
        : (row.spentMinutes / row.estimatedMinutes).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(context.space.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: context.radius.lgRadius,
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(row.listName, style: context.text.titleMedium),
              ),
              Text(
                'real ${DurationFormatter.hm(row.spentMinutes)}'
                ' / est. ${DurationFormatter.hm(row.estimatedMinutes)}',
                style: context.text.labelSmall,
              ),
            ],
          ),
          SizedBox(height: context.space.sm),
          ClipRRect(
            borderRadius: context.radius.pillRadius,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: colors.surfaceHigh,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ],
      ),
    );
  }
}
