import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../../../core/utils/formatters/percent_formatter.dart';
import '../../domain/entities/list_report.dart';
import '../../domain/entities/list_report_row.dart';
import '../../domain/entities/period_range.dart';
import '../../domain/entities/report_period_enum.dart';
import '../bloc/report_bloc.dart';
import '../period_label.dart';

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

  void _openDetail(
    BuildContext context,
    ListReportRow row,
    ReportPeriodEnum period,
    int offset,
  ) {
    final uri = Uri(
      path: Routes.reportDetail,
      queryParameters: {
        'list': row.listId,
        'period': period.name,
        'offset': '$offset',
      },
    ).toString();
    context.push(uri, extra: row.listName);
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
                    ReportLoaded(
                      :final report,
                      :final period,
                      :final range,
                      :final offset,
                      :final canGoForward,
                    ) =>
                      Column(
                        children: [
                          _PeriodNavigator(
                            period: period,
                            range: range,
                            canGoForward: canGoForward,
                          ),
                          Expanded(
                            child: report.isEmpty
                                ? const AppEmptyState(
                                    icon: Icons.bar_chart_rounded,
                                    title: 'Sem dados no período',
                                    message:
                                        'Registre tempo nas tarefas para ver o relatório.',
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.all(context.space.lg),
                                    itemCount: report.rows.length,
                                    separatorBuilder: (_, _) =>
                                        SizedBox(height: context.space.md),
                                    itemBuilder: (context, i) => _ReportRowTile(
                                      row: report.rows[i],
                                      index: i,
                                      shareRatio:
                                          report.shareRatio(report.rows[i]),
                                      sharePercent:
                                          report.sharePercent(report.rows[i]),
                                      onTap: () => _openDetail(
                                        context,
                                        report.rows[i],
                                        period,
                                        offset,
                                      ),
                                    ),
                                  ),
                          ),
                          if (!report.isEmpty) _ReportTotalBar(report: report),
                        ],
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

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.period,
    required this.range,
    required this.canGoForward,
  });

  final ReportPeriodEnum period;
  final PeriodRange range;
  final bool canGoForward;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.space.lg,
        vertical: context.space.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Anterior',
            onPressed: () =>
                context.read<ReportBloc>().add(const ReportPeriodStepped(-1)),
          ),
          Expanded(
            child: Text(
              reportPeriodLabel(period, range, DateTime.now()),
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Seguinte',
            onPressed: canGoForward
                ? () =>
                    context.read<ReportBloc>().add(const ReportPeriodStepped(1))
                : null,
          ),
        ],
      ),
    );
  }
}

/// Rodapé fixo com o total do período filtrado (real × estimado).
/// Os valores vêm prontos da entity `ListReport` — a UI só formata e exibe.
class _ReportTotalBar extends StatelessWidget {
  const _ReportTotalBar({required this.report});

  final ListReport report;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.space.lg,
        vertical: context.space.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total do período',
              style: context.text.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: context.space.sm),
          Text(
            'real ${DurationFormatter.hm(report.totalSpentMinutes)}'
            ' / est. ${DurationFormatter.hm(report.totalEstimatedMinutes)}',
            style: context.text.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _ReportRowTile extends StatelessWidget {
  const _ReportRowTile({
    required this.row,
    required this.index,
    required this.shareRatio,
    required this.sharePercent,
    required this.onTap,
  });

  final ListReportRow row;
  final int index;

  /// Fração (0..1) do tempo total gasto do período — preenchimento da barra.
  final double shareRatio;

  /// Participação do item no tempo total gasto (0..100); null se total = 0.
  final double? sharePercent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.categoryAt(index);
    final percent = sharePercent;

    return InkWell(
      onTap: onTap,
      borderRadius: context.radius.lgRadius,
      child: Container(
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
                SizedBox(width: context.space.xs),
                Icon(Icons.chevron_right_rounded, color: colors.textMuted),
              ],
            ),
            SizedBox(height: context.space.sm),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: context.radius.pillRadius,
                    child: LinearProgressIndicator(
                      value: shareRatio,
                      minHeight: 8,
                      backgroundColor: colors.surfaceHigh,
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ),
                if (percent != null) ...[
                  SizedBox(width: context.space.sm),
                  Text(
                    PercentFormatter.decimal1(percent),
                    style: context.text.labelSmall,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
