import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/day_config_entity.dart';
import '../../domain/usecases/set_available_minutes_use_case.dart';
import '../../domain/usecases/watch_config_use_case.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// Configurações do dia: horas disponíveis para o "cabe no dia" (Req. 4).
/// Só orquestra os UseCases; nenhuma regra de negócio aqui.
@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._watchConfig, this._setAvailableMinutes)
      : super(const SettingsLoading()) {
    on<SettingsStarted>(_onStarted);
    on<SettingsConfigUpdated>(_onConfigUpdated);
    on<AvailableMinutesChanged>(_onAvailableMinutesChanged);
  }

  final WatchConfigUseCase _watchConfig;
  final SetAvailableMinutesUseCase _setAvailableMinutes;

  StreamSubscription<Either<Failure, DayConfigEntity>>? _sub;

  Future<void> _onStarted(
    SettingsStarted e,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    await _sub?.cancel();
    _sub = _watchConfig(const NoParams())
        .listen((r) => add(SettingsConfigUpdated(r)));
  }

  void _onConfigUpdated(SettingsConfigUpdated e, Emitter<SettingsState> emit) {
    e.result.match(
      (f) => emit(const SettingsError()),
      (config) => emit(SettingsLoaded(config.availableMinutesPerDay)),
    );
  }

  Future<void> _onAvailableMinutesChanged(
    AvailableMinutesChanged e,
    Emitter<SettingsState> emit,
  ) async {
    final result =
        await _setAvailableMinutes(SetAvailableMinutesParams(e.minutes));
    // Sucesso reflete pelo stream de config; só o erro vira estado.
    result.match((f) => emit(const SettingsError()), (_) {});
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
