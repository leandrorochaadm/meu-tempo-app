import 'package:equatable/equatable.dart';

import 'overrun_alert_plan_entity.dart';

/// An alert that fired (what the banner shows).
class OverrunAlertEntity extends Equatable {
  const OverrunAlertEntity({
    required this.targetId,
    required this.title,
    required this.alertAt,
  });

  final String targetId;
  final String title;
  final DateTime alertAt;

  /// The alert still holds for the current series. Paused, stopped, switched
  /// target or removed estimate: the plan becomes `null` or another target.
  bool stillAppliesTo(OverrunAlertPlanEntity? plan) =>
      plan != null && plan.targetId == targetId;

  @override
  List<Object?> get props => [targetId, title, alertAt];
}
