import 'package:equatable/equatable.dart';

import '../../domain/entities/lock_screen_timer_entity.dart';
import '../../domain/lock_screen_rules.dart';
import '../background/lock_screen_channel_constants.dart';

/// Map of the lock screen timer sent to the native side (`show`).
class LockScreenTimerPayloadModel extends Equatable {
  const LockScreenTimerPayloadModel({
    required this.targetId,
    required this.targetType,
    required this.title,
    required this.listName,
    required this.status,
    required this.clockBaseEpochMillis,
    required this.elapsedMillis,
    required this.actions,
    required this.stopConfirmationWindowMillis,
  });

  factory LockScreenTimerPayloadModel.fromEntity(
    LockScreenTimerEntity entity, {
    required DateTime now,
  }) => LockScreenTimerPayloadModel(
    targetId: entity.targetId,
    targetType: entity.targetType.apiValue,
    title: entity.title,
    listName: entity.listName,
    status: entity.status.apiValue,
    clockBaseEpochMillis: entity.clockBase.millisecondsSinceEpoch,
    elapsedMillis: entity.elapsedAt(now).inMilliseconds,
    actions: List.unmodifiable(
      entity.availableActions.map((action) => action.apiValue),
    ),
    stopConfirmationWindowMillis:
        LockScreenRules.stopConfirmationWindow.inMilliseconds,
  );

  final String targetId;
  final String targetType;
  final String title;
  final String listName;
  final String status;
  final int clockBaseEpochMillis;
  final int elapsedMillis;
  final List<String> actions;
  final int stopConfirmationWindowMillis;

  Map<String, Object> toMap() => {
    LockScreenTimerPayloadKeys.targetId: targetId,
    LockScreenTimerPayloadKeys.targetType: targetType,
    LockScreenTimerPayloadKeys.title: title,
    LockScreenTimerPayloadKeys.listName: listName,
    LockScreenTimerPayloadKeys.status: status,
    LockScreenTimerPayloadKeys.clockBaseEpochMillis: clockBaseEpochMillis,
    LockScreenTimerPayloadKeys.elapsedMillis: elapsedMillis,
    LockScreenTimerPayloadKeys.actions: actions,
    LockScreenTimerPayloadKeys.stopConfirmationWindowMillis:
        stopConfirmationWindowMillis,
  };

  @override
  List<Object?> get props => [
    targetId,
    targetType,
    title,
    listName,
    status,
    clockBaseEpochMillis,
    elapsedMillis,
    actions,
    stopConfirmationWindowMillis,
  ];
}
