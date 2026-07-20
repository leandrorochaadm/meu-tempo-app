import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../domain/entities/list_report_row.dart';
import '../../domain/entities/report_period_enum.dart';
import '../bloc/report_bloc.dart';

/// Relatório de tempo por lista: estimado × real.
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  ReportPeriodEnum _period = ReportPeriodEnum.day;

  @override
  void initState() {
    super.initState();
    context.read<ReportBloc>().add(const ReportStarted());
  }

  void _selectPeriod(ReportPeriodEnum period) {
    if (period == _period) return;
    setState(() => _period = period);
    context.read<ReportBloc>().add(ReportPeriodChanged(period));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatório por lista')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _PeriodSelector(selected: _period, onSelected: _selectPeriod),
            Expanded(
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
                            title: 'Sem dados no período',
                            message:
                                'Registre tempo nas tarefas para ver o relatório.',
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
          ],
        ),
      ),
    );
  }
}

/// Seletor de período em chips (padrão `layout.md` — nunca dropdown).
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelected});

  final ReportPeriodEnum selected;
  final void Function(ReportPeriodEnum) onSelected;

  static const _labels = {
    ReportPeriodEnum.day: 'Dia',
    ReportPeriodEnum.week: 'Semana',
    ReportPeriodEnum.month: 'Mês',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.space.lg,
        vertical: context.space.sm,
      ),
      child: Wrap(
        spacing: context.space.sm,
        children: [
          for (final p in ReportPeriodEnum.values)
            ChoiceChip(
              label: Text(_labels[p]!),
              selected: p == selected,
              onSelected: (_) => onSelected(p),
            ),
        ],
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
