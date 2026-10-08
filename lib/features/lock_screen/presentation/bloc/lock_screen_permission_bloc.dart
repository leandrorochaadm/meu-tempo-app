import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_lock_screen_permission_status_use_case.dart';
import '../../domain/usecases/open_notification_settings_use_case.dart';
import '../../domain/usecases/watch_lock_screen_permission_warnings_use_case.dart';

part 'lock_screen_permission_event.dart';
part 'lock_screen_permission_state.dart';

/// Banner "Ative os avisos para ver o cronômetro com o celular bloqueado":
/// shows the banner on each domain warning
/// ([WatchLockScreenPermissionWarningsUseCase] — a start with notifications
/// off, never in the browser). No rule here: "is a start", "blocks" and "start
/// with notifications off warns" come ready from the domain.
///
/// A single sequential handler + subscription generation (same design as the
/// `LockScreenSyncBloc`): a late warning from a cancelled subscription does not
/// show the banner after signing out.
@injectable
class LockScreenPermissionBloc
    extends Bloc<LockScreenPermissionEvent, LockScreenPermissionState> {
  LockScreenPermissionBloc(
    this._watchWarnings,
    this._getPermissionStatus,
    this._openNotificationSettings,
  ) : super(const LockScreenPermissionBannerHidden()) {
    on<LockScreenPermissionEvent>(_onEvent, transformer: _sequential());
  }

  final WatchLockScreenPermissionWarningsUseCase _watchWarnings;
  final GetLockScreenPermissionStatusUseCase _getPermissionStatus;
  final OpenNotificationSettingsUseCase _openNotificationSettings;

  static const _logName = 'LockScreenPermission';

  StreamSubscription<Either<Failure, Unit>>? _warningsSub;

  /// Incremented on every (re)subscription and cancellation.
  int _generation = 0;

  /// One event at a time, in order (the `sequential()` algorithm from
  /// `bloc_concurrency`, without the dependency).
  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  Future<void> _onEvent(
    LockScreenPermissionEvent event,
    Emitter<LockScreenPermissionState> emit,
  ) => switch (event) {
    LockScreenPermissionStarted() => _subscribe(),
    LockScreenPermissionAppResumed() => _onAppResumed(emit),
    LockScreenPermissionStopped() => _onStopped(emit),
    LockScreenPermissionSettingsRequested() => _openSettings(),
    LockScreenPermissionBannerDismissed() => _hide(emit),
    final _LockScreenPermissionWarned warned => _onWarned(warned, emit),
  };

  Future<void> _subscribe() async {
    await _cancelSub();
    final generation = _generation;
    _warningsSub = _watchWarnings(const NoParams()).listen(
      (result) => result.match(
        _logPermissionFailure,
        (_) => add(_LockScreenPermissionWarned(generation)),
      ),
      onError: (Object error, StackTrace stackTrace) => AppLogger.logError(
        'Erro no fluxo de starts; faixa de avisos não avaliada.',
        error: error,
        stackTrace: stackTrace,
        name: _logName,
      ),
    );
  }

  Future<void> _onWarned(
    _LockScreenPermissionWarned event,
    Emitter<LockScreenPermissionState> emit,
  ) async {
    if (event.generation != _generation) return;
    emit(const LockScreenPermissionBannerVisible());
  }

  /// Resubscribes (the first reading becomes the new baseline) and, with the
  /// banner in view, checks whether the user turned notifications on.
  Future<void> _onAppResumed(Emitter<LockScreenPermissionState> emit) async {
    if (_warningsSub == null) return;
    await _subscribe();
    if (state is! LockScreenPermissionBannerVisible) return;
    final result = await _getPermissionStatus(const NoParams());
    result.match(_logPermissionFailure, (status) {
      if (!status.blocksLockScreen) {
        emit(const LockScreenPermissionBannerHidden());
      }
    });
  }

  Future<void> _onStopped(Emitter<LockScreenPermissionState> emit) async {
    await _cancelSub();
    emit(const LockScreenPermissionBannerHidden());
  }

  Future<void> _hide(Emitter<LockScreenPermissionState> emit) async =>
      emit(const LockScreenPermissionBannerHidden());

  Future<void> _openSettings() async {
    final result = await _openNotificationSettings(const NoParams());
    result.match(
      (failure) => AppLogger.logWarning(
        'Não foi possível abrir os Ajustes (${failure.runtimeType}).',
        name: _logName,
      ),
      (_) {},
    );
  }

  /// Failure reading the permission (on a start or coming back from the
  /// settings): log only, the banner neither shows nor hides.
  void _logPermissionFailure(Failure failure) => AppLogger.logWarning(
    'Não foi possível ler a permissão de avisos (${failure.runtimeType}).',
    name: _logName,
  );

  Future<void> _cancelSub() async {
    _generation++;
    final sub = _warningsSub;
    _warningsSub = null;
    await sub?.cancel();
  }

  @override
  Future<void> close() async {
    await _cancelSub();
    return super.close();
  }
}
