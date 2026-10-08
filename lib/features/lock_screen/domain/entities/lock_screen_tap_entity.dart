import 'package:equatable/equatable.dart';

import '../../../task/domain/entities/timer_target_type_enum.dart';

/// Tap on the lock screen timer **outside the buttons**: asks to open the app
/// straight on the task or appointment.
class LockScreenTapEntity extends Equatable {
  const LockScreenTapEntity({required this.targetId, required this.targetType});

  final String targetId;
  final TimerTargetTypeEnum targetType;

  @override
  List<Object?> get props => [targetId, targetType];
}
