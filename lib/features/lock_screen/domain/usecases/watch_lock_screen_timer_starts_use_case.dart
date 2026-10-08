import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/lock_screen_timer_entity.dart';
import 'watch_lock_screen_timer_use_case.dart';

/// Stream of timer **starts** (task or appointment) from now on: emits the
/// timer in view whenever a new session begins
/// ([LockScreenTimerEntity.startsSessionAfter]).
///
/// - The first reading after subscribing is the current state (e.g. opening the
///   app with the timer already running, or coming back to the foreground) and
///   does **not** count as a start: it becomes the comparison baseline.
/// - A read failure (`Left`) is ignored and does not change the baseline.
/// - Starting another target goes through "nothing in view" (`Right(null)`, see
///   `WatchLockScreenTimerUseCase`) and counts as a start of the new target.
@lazySingleton
class WatchLockScreenTimerStartsUseCase
    implements StreamUseCase<LockScreenTimerEntity, NoParams> {
  const WatchLockScreenTimerStartsUseCase(this._watchLockScreenTimer);

  final WatchLockScreenTimerUseCase _watchLockScreenTimer;

  @override
  Stream<LockScreenTimerEntity> call(NoParams params) {
    var hasBaseline = false;
    LockScreenTimerEntity? previous;
    // `expand` (not `async*`): cancelling goes straight to the source, instead
    // of waiting for the generator to reach its next `yield`.
    return _watchLockScreenTimer(params).expand((result) {
      if (result.isLeft()) return const <LockScreenTimerEntity>[];
      final current = result.getRight().toNullable();
      final isStart = hasBaseline &&
          current != null &&
          current.startsSessionAfter(previous);
      hasBaseline = true;
      previous = current;
      return isStart ? [current] : const <LockScreenTimerEntity>[];
    });
  }
}
