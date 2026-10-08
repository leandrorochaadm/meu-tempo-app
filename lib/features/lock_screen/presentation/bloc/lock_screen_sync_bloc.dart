import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/lock_screen_timer_entity.dart';
import '../../domain/usecases/sync_lock_screen_timer_use_case.dart';
import '../../domain/usecases/watch_lock_screen_timer_use_case.dart';

part 'lock_screen_sync_event.dart';
part 'lock_screen_sync_state.dart';

/// **Global** state that keeps the lock screen / notification shade equal to
/// the active timer: subscribes to [WatchLockScreenTimerUseCase] while the user
/// is signed in and relays each emission to [SyncLockScreenTimerUseCase]. No
/// business rule here: what shows comes ready from the domain, and the
/// show/clear choice lives in the UseCase.
///
/// All events go through a single sequential handler: the native call of one
/// event finishes before the next starts, so the gateway receives
/// `show`/`clear` in the order the timer changed.
@injectable
class LockScreenSyncBloc
    extends Bloc<LockScreenSyncEvent, LockScreenSyncState> {
  LockScreenSyncBloc(this._watchLockScreenTimer, this._syncLockScreenTimer)
    : super(const LockScreenSyncStopped()) {
    on<LockScreenSyncEvent>(_onEvent, transformer: _sequential());
  }

  final WatchLockScreenTimerUseCase _watchLockScreenTimer;
  final SyncLockScreenTimerUseCase _syncLockScreenTimer;

  static const _logName = 'LockScreenSync';

  StreamSubscription<Either<Failure, LockScreenTimerEntity?>>? _timerSub;

  /// Incremented on every (re)subscription and cancellation; drops events of
  /// old subscriptions still in the queue.
  int _generation = 0;

  /// Processes one event at a time, in arrival order (same algorithm as
  /// `sequential()` from `bloc_concurrency`).
  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  Future<void> _onEvent(
    LockScreenSyncEvent event,
    Emitter<LockScreenSyncState> emit,
  ) => switch (event) {
    LockScreenSyncStarted() => _subscribe(),
    LockScreenSyncAppResumed() => _onAppResumed(),
    LockScreenSyncSignedOut() => _onSignedOut(emit),
    final _LockScreenSyncTimerChanged changed => _onTimerChanged(changed, emit),
  };

  /// (Re)subscribes from scratch. The first emission of a new subscription is
  /// always relayed to the gateway: that is what "fixes" the lock screen when
  /// the app opens and when it returns to the foreground.
  Future<void> _subscribe() async {
    await _cancelSub();
    final generation = _generation;
    _timerSub = _watchLockScreenTimer(const NoParams()).listen(
      (result) => result.match(
        // Read failure: keep what is on screen (no `clear`), so a timer that
        // is still running does not vanish.
        (failure) => AppLogger.logWarning(
          'Failed to read the timer (${failure.runtimeType}); '
          'lock screen kept.',
          name: _logName,
        ),
        (timer) => add(_LockScreenSyncTimerChanged(timer, generation)),
      ),
      onError: (Object error, StackTrace stackTrace) => AppLogger.logError(
        'Error in the timer stream; lock screen kept.',
        error: error,
        stackTrace: stackTrace,
        name: _logName,
      ),
    );
  }

  /// Signed out there is nothing to reconcile.
  Future<void> _onAppResumed() async {
    if (_timerSub == null) return;
    await _subscribe();
  }

  Future<void> _onSignedOut(Emitter<LockScreenSyncState> emit) async {
    await _cancelSub();
    final result = await _syncLockScreenTimer(
      const SyncLockScreenTimerParams(timer: null),
    );
    result.match(
      (failure) => AppLogger.logWarning(
        'Could not clear the lock screen on sign-out '
        '(${failure.runtimeType}).',
        name: _logName,
      ),
      (_) {},
    );
    emit(const LockScreenSyncStopped());
  }

  Future<void> _onTimerChanged(
    _LockScreenSyncTimerChanged event,
    Emitter<LockScreenSyncState> emit,
  ) async {
    // Event from a subscription already cancelled (sign-out or foreground
    // return midway): ignore.
    if (event.generation != _generation) return;
    final timer = event.timer;
    final result = await _syncLockScreenTimer(
      SyncLockScreenTimerParams(timer: timer),
    );
    result.match(
      (failure) => AppLogger.logWarning(
        'The phone did not update the lock screen (${failure.runtimeType}).',
        name: _logName,
      ),
      (_) => emit(
        timer == null
            ? const LockScreenSyncHidden()
            : LockScreenSyncVisible(timer),
      ),
    );
  }

  Future<void> _cancelSub() async {
    _generation++;
    final sub = _timerSub;
    _timerSub = null;
    await sub?.cancel();
  }

  @override
  Future<void> close() async {
    await _cancelSub();
    return super.close();
  }
}
