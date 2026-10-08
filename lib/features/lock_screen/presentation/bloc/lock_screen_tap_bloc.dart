import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/lock_screen_tap_entity.dart';
import '../../domain/usecases/watch_lock_screen_taps_use_case.dart';

part 'lock_screen_tap_event.dart';
part 'lock_screen_tap_state.dart';

/// Receives taps on the lock screen timer (outside the buttons) and keeps them
/// until the screen navigates to the target (`LockScreenTapNavigator`). The
/// Bloc does not navigate: it only exposes the pending tap.
@injectable
class LockScreenTapBloc extends Bloc<LockScreenTapEvent, LockScreenTapState> {
  LockScreenTapBloc(this._watchTaps) : super(const LockScreenTapIdle()) {
    on<LockScreenTapStarted>(_onStarted);
    on<_LockScreenTapReceived>(_onReceived);
    on<LockScreenTapHandled>(_onHandled);
  }

  final WatchLockScreenTapsUseCase _watchTaps;

  StreamSubscription<LockScreenTapEntity>? _tapsSub;

  Future<void> _onStarted(
    LockScreenTapStarted event,
    Emitter<LockScreenTapState> emit,
  ) async {
    await _tapsSub?.cancel();
    _tapsSub = _watchTaps(const NoParams()).listen(
      (tap) => add(_LockScreenTapReceived(tap)),
      onError: (Object error, StackTrace stackTrace) => AppLogger.logError(
        'Erro no fluxo de toques da tela bloqueada.',
        error: error,
        stackTrace: stackTrace,
        name: 'LockScreenTap',
      ),
    );
  }

  void _onReceived(
    _LockScreenTapReceived event,
    Emitter<LockScreenTapState> emit,
  ) =>
      emit(LockScreenTapPending(event.tap));

  /// Only clears if the pending one is still the same tap (a new tap that
  /// arrived in the meantime stays pending).
  void _onHandled(LockScreenTapHandled event, Emitter<LockScreenTapState> emit) {
    if (state == LockScreenTapPending(event.tap)) {
      emit(const LockScreenTapIdle());
    }
  }

  @override
  Future<void> close() async {
    await _tapsSub?.cancel();
    return super.close();
  }
}
