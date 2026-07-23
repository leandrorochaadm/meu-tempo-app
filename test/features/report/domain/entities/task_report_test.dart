import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/report/domain/entities/report_tree_node.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

void main() {
  ReportTreeNode node(String id, {required int spent}) => ReportTreeNode(
        id: id,
        title: id,
        targetType: TimerTargetTypeEnum.task,
        level: 0,
        spentMinutes: spent,
      );

  test('shareRatio e sharePercent = participação do nó no total gasto', () {
    final a = node('a', spent: 120);
    final b = node('b', spent: 60);
    final report = TaskReport(
      nodes: [a, b],
      totalSpentMinutes: 180,
      totalEstimatedMinutes: 60,
    );

    expect(report.shareRatio(a), closeTo(0.6667, 0.0001));
    expect(report.shareRatio(b), closeTo(0.3333, 0.0001));
    expect(report.sharePercent(a), closeTo(66.67, 0.01));
    expect(report.sharePercent(b), closeTo(33.33, 0.01));
  });

  test('share é 0/null quando o total gasto é zero', () {
    final a = node('a', spent: 0);
    final report = TaskReport(
      nodes: [a],
      totalSpentMinutes: 0,
      totalEstimatedMinutes: 0,
    );

    expect(report.shareRatio(a), 0);
    expect(report.sharePercent(a), isNull);
  });
}
