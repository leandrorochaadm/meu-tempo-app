import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../config/domain/entities/day_config_entity.dart';
import '../../../config/domain/usecases/watch_config_use_case.dart';
import '../../../list/domain/usecases/ensure_inbox_exists_use_case.dart';
import '../../../task/domain/entities/task_entity.dart';
import '../../../task/domain/usecases/watch_tasks_use_case.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/day_fit.dart';
import '../../domain/failures.dart';
import '../../domain/usecases/check_fits_in_day_use_case.dart';
import '../../domain/usecases/create_appointment_use_case.dart';
import '../../domain/usecases/delete_appointment_use_case.dart';
import '../../domain/usecases/watch_appointments_for_day_use_case.dart';

part 'agenda_event.dart';
part 'agenda_state.dart';

/// Orquestra a agenda do dia: compromissos + "cabe no dia" (aviso). Combina os
/// streams de compromissos, config e tarefas; a soma vive no UseCase.
@injectable
class AgendaBloc extends Bloc<AgendaEvent, AgendaState> {
  AgendaBloc(
    this._watchAppointments,
    this._createAppointment,
    this._deleteAppointment,
    this._checkFits,
    this._watchConfig,
    this._watchTasks,
    this._ensureInbox,
  ) : super(const AgendaLoading()) {
    on<AgendaStarted>(_onStarted);
    on<AgendaAppointmentsUpdated>(_onAppointmentsUpdated);
    on<AgendaConfigUpdated>(_onConfigUpdated);
    on<AgendaTasksUpdated>(_onTasksUpdated);
    on<AppointmentCreated>(_onCreated);
    on<AppointmentDeleted>(_onDeleted);
  }

  final WatchAppointmentsForDayUseCase _watchAppointments;
  final CreateAppointmentUseCase _createAppointment;
  final DeleteAppointmentUseCase _deleteAppointment;
  final CheckFitsInDayUseCase _checkFits;
  final WatchConfigUseCase _watchConfig;
  final WatchTasksUseCase _watchTasks;
  final EnsureInboxExistsUseCase _ensureInbox;

  StreamSubscription<Either<Failure, List<AppointmentEntity>>>? _apptSub;
  StreamSubscription<Either<Failure, DayConfigEntity>>? _configSub;
  StreamSubscription<Either<Failure, List<TaskEntity>>>? _tasksSub;

  late DateTime _today;
  String? _inboxListId;
  List<AppointmentEntity> _appointments = const [];
  List<TaskEntity> _tasks = const [];
  int _availableMinutes = 480;

  Future<void> _onStarted(AgendaStarted e, Emitter<AgendaState> emit) async {
    emit(const AgendaLoading());
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);

    final inbox = await _ensureInbox(const NoParams());
    _inboxListId = inbox.getRight().toNullable()?.id;

    await _apptSub?.cancel();
    _apptSub = _watchAppointments(DayParams(_today))
        .listen((r) => add(AgendaAppointmentsUpdated(r)));

    await _configSub?.cancel();
    _configSub = _watchConfig(const NoParams())
        .listen((r) => add(AgendaConfigUpdated(r)));

    await _tasksSub?.cancel();
    _tasksSub =
        _watchTasks(const NoParams()).listen((r) => add(AgendaTasksUpdated(r)));
  }

  void _onAppointmentsUpdated(
    AgendaAppointmentsUpdated e,
    Emitter<AgendaState> emit,
  ) {
    e.result.match((f) => emit(AgendaError(_mapFailure(f))), (list) {
      _appointments = [...list]..sort((a, b) => a.startMinute.compareTo(b.startMinute));
      _emit(emit);
    });
  }

  void _onConfigUpdated(AgendaConfigUpdated e, Emitter<AgendaState> emit) {
    e.result.match((_) {}, (config) {
      _availableMinutes = config.availableMinutesPerDay;
      _emit(emit);
    });
  }

  void _onTasksUpdated(AgendaTasksUpdated e, Emitter<AgendaState> emit) {
    e.result.match((_) {}, (tasks) {
      _tasks = tasks;
      _emit(emit);
    });
  }

  void _emit(Emitter<AgendaState> emit) {
    final taskDurations = _tasks
        .where((t) =>
            !t.hasChildren &&
            !t.isDone &&
            t.dueDate != null &&
            _isSameDay(t.dueDate!, _today))
        .map((t) => t.estimatedMinutes ?? 0)
        .toList();
    final apptDurations = _appointments.map((a) => a.durationMinutes).toList();

    final fit = _checkFits(
      taskDurations: taskDurations,
      appointmentDurations: apptDurations,
      availableMinutes: _availableMinutes,
    );
    emit(AgendaLoaded(appointments: _appointments, fit: fit));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _onCreated(
    AppointmentCreated e,
    Emitter<AgendaState> emit,
  ) async {
    final listId = _inboxListId;
    if (listId == null) return;
    final result = await _createAppointment(CreateAppointmentParams(
      title: e.title,
      listId: listId,
      date: _today,
      startMinute: e.startMinute,
      durationMinutes: e.durationMinutes,
    ));
    result.match((f) => emit(AgendaError(_mapFailure(f))), (_) {});
  }

  Future<void> _onDeleted(
    AppointmentDeleted e,
    Emitter<AgendaState> emit,
  ) async {
    final result =
        await _deleteAppointment(DeleteAppointmentParams(e.appointmentId));
    result.match((f) => emit(AgendaError(_mapFailure(f))), (_) {});
  }

  String _mapFailure(Failure failure) => switch (failure) {
        EmptyAppointmentTitleFailure() => 'Digite um título.',
        InvalidAppointmentDurationFailure() => 'Informe uma duração válida.',
        NetworkFailure() => 'Sem conexão. Verifique a internet.',
        _ => 'Algo deu errado. Tente novamente.',
      };

  @override
  Future<void> close() {
    _apptSub?.cancel();
    _configSub?.cancel();
    _tasksSub?.cancel();
    return super.close();
  }
}
