import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_context_extensions.dart';
import '../../../../core/ui/app_empty_state.dart';
import '../../../../core/ui/app_list_skeleton.dart';
import '../../../../core/utils/formatters/duration_formatter.dart';
import '../../../../core/utils/formatters/percent_formatter.dart';
import '../../../task/domain/entities/timer_target_type_enum.dart';
import '../../domain/entities/report_period_enum.dart';
import '../../domain/entities/report_tree_node.dart';
import '../../domain/entities/task_report_sort_enum.dart';
import '../bloc/report_detail_bloc.dart';
import '../period_label.dart';

/// Detalhe do relatório de uma lista: árvore (avó → filha → neta) das tarefas
/// com tempo no período + compromissos, com gasto × estimado + estouro.
/// Cada raiz é um acordeão: tocar expande as filhas/netas inline.
class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({
    super.key,
    required this.listId,
    required this.period,
    required this.offset,
    this.listName,
  });

  final String listId;
  final ReportPeriodEnum period;
  final int offset;
  final String? listName;

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    context.read<ReportDetailBloc>().add(ReportDetailStarted(
          listId: widget.listId,
          period: widget.period,
          offset: widget.offset,
          listName: widget.listName,
        ));
  }

  void _toggle(String id) => setState(
        () => _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ReportDetailBloc, ReportDetailState>(
          builder: (context, state) {
            return switch (state) {
              ReportDetailLoading() => const _Scaffold(
                  title: 'Relatório',
                  child: AppListSkeleton(),
                ),
              ReportDetailError() => const _Scaffold(
                  title: 'Relatório',
                  child: AppEmptyState(
                    icon: Icons.bar_chart_rounded,
                    title: 'Não foi possível carregar',
                    message: 'Tente novamente em instantes.',
                  ),
                ),
              ReportDetailLoaded(
                :final report,
                :final listName,
                :final range,
                :final period,
                :final sort,
              ) =>
                _Scaffold(
                  title:
                      '$listName · ${reportPeriodLabel(period, range, DateTime.now())}',
                  child: report.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.bar_chart_rounded,
                          title: 'Sem tempo no período',
                          message:
                              'Nenhuma tarefa desta lista teve tempo registrado.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TotalHeader(
                              spent: report.totalSpentMinutes,
                              estimated: report.totalEstimatedMinutes,
                            ),
                            _SortSelector(selected: sort),
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.all(context.space.lg),
                                children: [
                                  for (final root in report.nodes)
                                    ..._renderRoot(report, root),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
            };
          },
        ),
      ),
    );
  }

  /// Renderiza uma raiz e, se expandida, seus descendentes achatados+indentados.
  List<Widget> _renderRoot(TaskReport report, ReportTreeNode root) {
    final widgets = <Widget>[
      Padding(
        padding: EdgeInsets.only(bottom: context.space.md),
        child: _NodeTile(
          node: root,
          shareRatio: report.shareRatio(root),
          sharePercent: report.sharePercent(root),
          expandable: !root.isLeaf,
          expanded: _expanded.contains(root.id),
          onTap: root.isLeaf ? null : () => _toggle(root.id),
        ),
      ),
    ];
    if (!root.isLeaf && _expanded.contains(root.id)) {
      _appendDescendants(report, root, widgets);
    }
    return widgets;
  }

  void _appendDescendants(
    TaskReport report,
    ReportTreeNode node,
    List<Widget> out,
  ) {
    for (final child in node.children) {
      out.add(Padding(
        padding: EdgeInsets.only(bottom: context.space.md),
        child: _NodeTile(
          node: child,
          shareRatio: report.shareRatio(child),
          sharePercent: report.sharePercent(child),
          expandable: false,
          expanded: false,
        ),
      ));
      if (!child.isLeaf) _appendDescendants(report, child, out);
    }
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBar(title: Text(title)),
        Expanded(child: child),
      ],
    );
  }
}

class _TotalHeader extends StatelessWidget {
  const _TotalHeader({required this.spent, required this.estimated});
  final int spent;
  final int estimated;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.space.lg,
        vertical: context.space.sm,
      ),
      child: Text(
        'gasto ${DurationFormatter.hm(spent)}'
        ' · est. ${DurationFormatter.hm(estimated)}',
        style: context.text.labelSmall,
      ),
    );
  }
}

class _SortSelector extends StatelessWidget {
  const _SortSelector({required this.selected});
  final TaskReportSortEnum selected;

  static const _labels = {
    TaskReportSortEnum.spent: 'Tempo',
    TaskReportSortEnum.overrun: 'Estouro',
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
          for (final s in TaskReportSortEnum.values)
            ChoiceChip(
              label: Text(_labels[s]!),
              selected: s == selected,
              onSelected: (_) =>
                  context.read<ReportDetailBloc>().add(ReportDetailSortChanged(s)),
            ),
        ],
      ),
    );
  }
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({
    required this.node,
    required this.shareRatio,
    required this.sharePercent,
    required this.expandable,
    required this.expanded,
    this.onTap,
  });

  final ReportTreeNode node;

  /// Fração (0..1) do tempo total gasto do período — preenchimento da barra.
  final double shareRatio;

  /// Participação do item no tempo total gasto (0..100); null se total = 0.
  final double? sharePercent;
  final bool expandable;
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.categoryAt(node.level);
    final isAppointment = node.targetType == TimerTargetTypeEnum.appointment;

    final tile = Container(
      margin: EdgeInsets.only(left: context.space.xl * node.level),
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
              if (!node.isLeaf)
                Padding(
                  padding: EdgeInsets.only(right: context.space.sm),
                  child: Icon(
                    expanded
                        ? Icons.expand_more_rounded
                        : Icons.chevron_right_rounded,
                    color: colors.textMuted,
                  ),
                ),
              Expanded(
                child: Text(
                  isAppointment ? '${node.title} (compr.)' : node.title,
                  style: context.text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: context.space.xs),
          Text(_subtitle(), style: context.text.labelSmall),
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
              if (sharePercent != null) ...[
                SizedBox(width: context.space.sm),
                Text(
                  PercentFormatter.decimal1(sharePercent!),
                  style: context.text.labelSmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return tile;
    return InkWell(
      onTap: onTap,
      borderRadius: context.radius.lgRadius,
      child: tile,
    );
  }

  String _subtitle() {
    final spent = 'gasto ${DurationFormatter.hm(node.spentMinutes)}';
    final overrun = node.overrunMinutes;
    if (overrun == null) return '$spent · —'; // compromisso: sem estimativa
    final est = 'est. ${DurationFormatter.hm(node.estimatedMinutes!)}';
    final delta = switch (overrun) {
      0 => '0',
      > 0 => '+${DurationFormatter.hm(overrun)}',
      _ => '-${DurationFormatter.hm(-overrun)}',
    };
    return '$spent · $est · $delta';
  }
}
