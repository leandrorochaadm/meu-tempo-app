import 'package:equatable/equatable.dart';

import '../../../task/domain/entities/timer_status_enum.dart';
import '../../../task/domain/entities/timer_target_type_enum.dart';
import 'lock_screen_action_enum.dart';

/// What the lock screen shows of the active timer, the same for task and
/// appointment: name, list and time (already spent + current session). The
/// estimated time is not part of it.
class LockScreenTimerEntity extends Equatable {
  const LockScreenTimerEntity({
    required this.targetId,
    required this.targetType,
    required this.title,
    required this.listName,
    required this.status,
    required this.spentMinutes,
    required this.sessionStartedAt,
  });

  /// Leaf task or appointment id; sent along with every action and tap.
  final String targetId;
  final TimerTargetTypeEnum targetType;
  final String title;

  /// Name of the target's list (empty when the list was not found).
  final String listName;
  final TimerStatusEnum status;

  /// Minutes already spent on the target **before** the current session.
  final int spentMinutes;

  /// Running: start of the current session. Paused: instant of the pause.
  final DateTime sessionStartedAt;

  bool get isRunning => status == TimerStatusEnum.running;

  bool get isPaused => status == TimerStatusEnum.paused;

  Duration get spentBeforeSession => Duration(minutes: spentMinutes);

  /// Instant at which the clock would read 00:00 if all the target's time
  /// were one session. While running, the native clock counts from here.
  DateTime get clockBase => sessionStartedAt.subtract(spentBeforeSession);

  /// Time shown at [now]: spent + current session (running) or only the spent
  /// time (paused, since the session was added to it on pause).
  Duration elapsedAt(DateTime now) {
    if (isPaused) return spentBeforeSession;
    final session = now.difference(sessionStartedAt);
    return spentBeforeSession + (session.isNegative ? Duration.zero : session);
  }

  /// Buttons in display order: running → pause and stop; paused → resume and
  /// stop.
  List<LockScreenActionEnum> get availableActions => isRunning
      ? const [LockScreenActionEnum.pause, LockScreenActionEnum.stopConfirmed]
      : const [LockScreenActionEnum.resume, LockScreenActionEnum.stopConfirmed];

  @override
  List<Object?> get props => [
        targetId,
        targetType,
        title,
        listName,
        status,
        spentMinutes,
        sessionStartedAt,
      ];
}
