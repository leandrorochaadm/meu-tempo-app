import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../task/domain/usecases/pause_timer_use_case.dart';
import '../../domain/entities/overrun_alert_entity.dart';
import '../../domain/entities/overrun_alert_plan_entity.dart';
import '../../domain/usecases/sync_overrun_alert_schedule_use_case.dart';
import '../../domain/usecases/watch_overrun_alert_plan_use_case.dart';
import '../../domain/usecases/watch_overrun_alerts_use_case.dart';

part 'overrun_alert_event.dart';
part 'overrun_alert_state.dart';

/// **Global** state of the overrun alert: relays the plan from the domain to
/// the scheduler and shows the alerts it fires. No business rule here: when to
/// alert, the next time and "the alert still holds" come from the domain.
///
/// All events go through a single sequential handler, so `schedule`/`cancel`
/// reach the scheduler in the order the timer changed.
@injectable
class OverrunAlertBloc extends Bloc<OverrunAlertEvent, OverrunAlertState> {
  OverrunAlertBloc(
    this._watchPlan,
    this._syncSchedule,
    this._watchAlerts,
    this._pauseTimer,
  ) : super(const OverrunAlertHidden()) {
    on<OverrunAlertEvent>(_onEvent, transformer: _sequential());
  }

  final WatchOverrunAlertPlanUseCase _watchPlan;
  final SyncOverrunAlertScheduleUseCase _syncSchedule;
  final WatchOverrunAlertsUseCase _watchAlerts;
  final PauseTimerUseCase _pauseTimer;

  static const _logName = 'OverrunAlert';

  StreamSubscription<Either<Failure, OverrunAlertPlanEntity?>>? _planSub;
  StreamSubscription<OverrunAlertEntity>? _alertsSub;
  OverrunAlertPlanEntity? _plan;

  /// Incremented on every (re)subscription and cancellation; drops events of
  /// old subscriptions still in the queue.
  int _generation = 0;

  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  Future<void> _onEvent(
    OverrunAlertEvent event,
    Emitter<OverrunAlertState> emit,
  ) => switch (event) {
    OverrunAlertStarted() => _subscribe(),
    OverrunAlertSignedOut() => _onSignedOut(emit),
    OverrunAlertDismissed() => _onDismissed(emit),
    OverrunAlertPauseRequested() => _onPauseRequested(emit),
    final _OverrunAlertPlanChanged changed => _onPlanChanged(changed, emit),
    final _OverrunAlertFired fired => _onFired(fired, emit),
  };

  Future<void> _subscribe() async {
    await _cancelSubs();
    final generation = _generation;
    // Alerts first: no firing is lost between the two subscriptions.
    _alertsSub = _watchAlerts(const NoParams()).listen(
      (alert) => add(_OverrunAlertFired(alert, generation)),
      onError: (Object error, StackTrace stackTrace) => AppLogger.logError(
        'Error in the alerts stream.',
        error: error,
        stackTrace: stackTrace,
        name: _logName,
      ),
    );
    _planSub = _watchPlan(const NoParams()).listen(
      (result) => result.match(
        // Read failure: keep the current schedule.
        (failure) => AppLogger.logWarning(
          'Failed to read the plan (${failure.runtimeType}); schedule kept.',
          name: _logName,
        ),
        (plan) => add(_OverrunAlertPlanChanged(plan, generation)),
      ),
      onError: (Object error, StackTrace stackTrace) => AppLogger.logError(
        'Error in the plan stream; schedule kept.',
        error: error,
        stackTrace: stackTrace,
        name: _logName,
      ),
    );
  }

  Future<void> _onPlanChanged(
    _OverrunAlertPlanChanged event,
    Emitter<OverrunAlertState> emit,
  ) async {
    if (event.generation != _generation) return;
    _plan = event.plan;
    await _sync(event.plan);
    final alert = _currentAlert;
    if (alert != null && !alert.stillAppliesTo(_plan)) {
      emit(const OverrunAlertHidden());
    }
  }

  Future<void> _onFired(
    _OverrunAlertFired event,
    Emitter<OverrunAlertState> emit,
  ) async {
    if (event.generation != _generation) return;
    if (event.alert.stillAppliesTo(_plan)) {
      emit(OverrunAlertVisible(event.alert));
    }
  }

  Future<void> _onDismissed(Emitter<OverrunAlertState> emit) async =>
      emit(const OverrunAlertHidden());

  Future<void> _onPauseRequested(Emitter<OverrunAlertState> emit) async {
    final alert = _currentAlert;
    if (alert == null) return;
    // Equal states are not re-emitted: going back to Visible makes a second
    // consecutive failure show the message again.
    if (state is OverrunAlertPauseFailed) emit(OverrunAlertVisible(alert));
    final result = await _pauseTimer(
      PauseTimerParams(targetId: alert.targetId, now: DateTime.now()),
    );
    result.match(
      (failure) => emit(OverrunAlertPauseFailed(alert, _mapFailure(failure))),
      // The plan stream emits `null` and cancels the series.
      (_) => emit(const OverrunAlertHidden()),
    );
  }

  Future<void> _onSignedOut(Emitter<OverrunAlertState> emit) async {
    await _cancelSubs();
    _plan = null;
    await _sync(null);
    emit(const OverrunAlertHidden());
  }

  Future<void> _sync(OverrunAlertPlanEntity? plan) async {
    final result = await _syncSchedule(
      SyncOverrunAlertScheduleParams(plan: plan),
    );
    result.match(
      (failure) => AppLogger.logWarning(
        'Could not update the alert schedule (${failure.runtimeType}).',
        name: _logName,
      ),
      (_) {},
    );
  }

  OverrunAlertEntity? get _currentAlert => switch (state) {
    OverrunAlertVisible(:final alert) => alert,
    OverrunAlertPauseFailed(:final alert) => alert,
    OverrunAlertHidden() => null,
  };

  String _mapFailure(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem conexão. Verifique a internet.',
    _ => 'Não foi possível pausar. Tente de novo.',
  };

  Future<void> _cancelSubs() async {
    _generation++;
    final plan = _planSub;
    final alerts = _alertsSub;
    _planSub = null;
    _alertsSub = null;
    await plan?.cancel();
    await alerts?.cancel();
  }

  @override
  Future<void> close() async {
    await _cancelSubs();
    return super.close();
  }
}
