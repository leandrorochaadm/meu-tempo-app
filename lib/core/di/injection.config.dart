// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:meu_tempo/core/di/injection.dart' as _i767;
import 'package:meu_tempo/features/appointment/data/datasources/appointment_remote_data_source.dart'
    as _i621;
import 'package:meu_tempo/features/appointment/data/repositories/appointment_repository_impl.dart'
    as _i266;
import 'package:meu_tempo/features/appointment/domain/repositories/appointment_repository.dart'
    as _i259;
import 'package:meu_tempo/features/appointment/domain/usecases/check_fits_in_day_use_case.dart'
    as _i483;
import 'package:meu_tempo/features/appointment/domain/usecases/create_appointment_use_case.dart'
    as _i176;
import 'package:meu_tempo/features/appointment/domain/usecases/delete_appointment_use_case.dart'
    as _i502;
import 'package:meu_tempo/features/appointment/domain/usecases/register_appointment_time_use_case.dart'
    as _i543;
import 'package:meu_tempo/features/appointment/domain/usecases/watch_all_appointments_use_case.dart'
    as _i897;
import 'package:meu_tempo/features/appointment/domain/usecases/watch_appointments_for_day_use_case.dart'
    as _i777;
import 'package:meu_tempo/features/appointment/presentation/bloc/agenda_bloc.dart'
    as _i990;
import 'package:meu_tempo/features/auth/data/datasources/auth_remote_data_source.dart'
    as _i788;
import 'package:meu_tempo/features/auth/data/repositories/auth_repository_impl.dart'
    as _i534;
import 'package:meu_tempo/features/auth/domain/repositories/auth_repository.dart'
    as _i224;
import 'package:meu_tempo/features/auth/domain/usecases/sign_in_with_google_use_case.dart'
    as _i98;
import 'package:meu_tempo/features/auth/domain/usecases/sign_out_use_case.dart'
    as _i846;
import 'package:meu_tempo/features/auth/domain/usecases/watch_auth_state_use_case.dart'
    as _i1046;
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart'
    as _i708;
import 'package:meu_tempo/features/config/data/datasources/config_remote_data_source.dart'
    as _i584;
import 'package:meu_tempo/features/config/data/repositories/config_repository_impl.dart'
    as _i62;
import 'package:meu_tempo/features/config/domain/repositories/config_repository.dart'
    as _i330;
import 'package:meu_tempo/features/config/domain/usecases/set_available_minutes_use_case.dart'
    as _i949;
import 'package:meu_tempo/features/config/domain/usecases/watch_config_use_case.dart'
    as _i559;
import 'package:meu_tempo/features/config/presentation/bloc/settings_bloc.dart'
    as _i830;
import 'package:meu_tempo/features/list/data/datasources/task_list_remote_data_source.dart'
    as _i813;
import 'package:meu_tempo/features/list/data/repositories/task_list_repository_impl.dart'
    as _i924;
import 'package:meu_tempo/features/list/domain/repositories/task_list_repository.dart'
    as _i219;
import 'package:meu_tempo/features/list/domain/usecases/create_list_use_case.dart'
    as _i488;
import 'package:meu_tempo/features/list/domain/usecases/delete_list_use_case.dart'
    as _i666;
import 'package:meu_tempo/features/list/domain/usecases/ensure_inbox_exists_use_case.dart'
    as _i655;
import 'package:meu_tempo/features/list/domain/usecases/rename_list_use_case.dart'
    as _i202;
import 'package:meu_tempo/features/list/domain/usecases/watch_lists_use_case.dart'
    as _i689;
import 'package:meu_tempo/features/list/presentation/bloc/list_manager_bloc.dart'
    as _i427;
import 'package:meu_tempo/features/migration/domain/usecases/get_pending_migrations_use_case.dart'
    as _i842;
import 'package:meu_tempo/features/migration/domain/usecases/migrate_task_use_case.dart'
    as _i798;
import 'package:meu_tempo/features/migration/presentation/bloc/migration_bloc.dart'
    as _i492;
import 'package:meu_tempo/features/report/domain/usecases/get_list_report_use_case.dart'
    as _i67;
import 'package:meu_tempo/features/report/domain/usecases/get_task_report_use_case.dart'
    as _i838;
import 'package:meu_tempo/features/report/presentation/bloc/report_bloc.dart'
    as _i318;
import 'package:meu_tempo/features/report/presentation/bloc/report_detail_bloc.dart'
    as _i73;
import 'package:meu_tempo/features/task/data/datasources/task_remote_data_source.dart'
    as _i592;
import 'package:meu_tempo/features/task/data/datasources/time_entry_remote_data_source.dart'
    as _i52;
import 'package:meu_tempo/features/task/data/datasources/timer_remote_data_source.dart'
    as _i588;
import 'package:meu_tempo/features/task/data/repositories/task_repository_impl.dart'
    as _i1011;
import 'package:meu_tempo/features/task/data/repositories/time_entry_repository_impl.dart'
    as _i877;
import 'package:meu_tempo/features/task/data/repositories/timer_repository_impl.dart'
    as _i825;
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart'
    as _i521;
import 'package:meu_tempo/features/task/domain/repositories/time_entry_repository.dart'
    as _i706;
import 'package:meu_tempo/features/task/domain/repositories/timer_repository.dart'
    as _i381;
import 'package:meu_tempo/features/task/domain/usecases/add_subtask_use_case.dart'
    as _i650;
import 'package:meu_tempo/features/task/domain/usecases/build_task_tree_use_case.dart'
    as _i27;
import 'package:meu_tempo/features/task/domain/usecases/complete_task_use_case.dart'
    as _i623;
import 'package:meu_tempo/features/task/domain/usecases/create_task_use_case.dart'
    as _i658;
import 'package:meu_tempo/features/task/domain/usecases/delete_task_use_case.dart'
    as _i162;
import 'package:meu_tempo/features/task/domain/usecases/edit_task_use_case.dart'
    as _i43;
import 'package:meu_tempo/features/task/domain/usecases/get_prioritized_leaves_use_case.dart'
    as _i1067;
import 'package:meu_tempo/features/task/domain/usecases/move_task_use_case.dart'
    as _i213;
import 'package:meu_tempo/features/task/domain/usecases/register_manual_time_use_case.dart'
    as _i1025;
import 'package:meu_tempo/features/task/domain/usecases/restore_tasks_use_case.dart'
    as _i942;
import 'package:meu_tempo/features/task/domain/usecases/seed_first_access_use_case.dart'
    as _i159;
import 'package:meu_tempo/features/task/domain/usecases/start_timer_use_case.dart'
    as _i210;
import 'package:meu_tempo/features/task/domain/usecases/stop_timer_use_case.dart'
    as _i726;
import 'package:meu_tempo/features/task/domain/usecases/watch_active_timer_use_case.dart'
    as _i397;
import 'package:meu_tempo/features/task/domain/usecases/watch_tasks_use_case.dart'
    as _i1035;
import 'package:meu_tempo/features/task/domain/usecases/watch_time_entries_use_case.dart'
    as _i892;
import 'package:meu_tempo/features/task/presentation/bloc/task_list_bloc.dart'
    as _i35;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final firebaseModule = _$FirebaseModule();
    gh.lazySingleton<_i59.FirebaseAuth>(() => firebaseModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(() => firebaseModule.firestore);
    gh.lazySingleton<_i483.CheckFitsInDayUseCase>(
      () => const _i483.CheckFitsInDayUseCase(),
    );
    gh.lazySingleton<_i842.GetPendingMigrationsUseCase>(
      () => const _i842.GetPendingMigrationsUseCase(),
    );
    gh.lazySingleton<_i67.GetListReportUseCase>(
      () => const _i67.GetListReportUseCase(),
    );
    gh.lazySingleton<_i838.GetTaskReportUseCase>(
      () => const _i838.GetTaskReportUseCase(),
    );
    gh.lazySingleton<_i27.BuildTaskTreeUseCase>(
      () => const _i27.BuildTaskTreeUseCase(),
    );
    gh.lazySingleton<_i1067.GetPrioritizedLeavesUseCase>(
      () => const _i1067.GetPrioritizedLeavesUseCase(),
    );
    gh.lazySingleton<_i813.TaskListRemoteDataSource>(
      () => _i813.TaskListRemoteDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i788.AuthRemoteDataSource>(
      () => _i788.AuthRemoteDataSourceImpl(gh<_i59.FirebaseAuth>()),
    );
    gh.lazySingleton<_i621.AppointmentRemoteDataSource>(
      () => _i621.AppointmentRemoteDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i52.TimeEntryRemoteDataSource>(
      () => _i52.TimeEntryRemoteDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i592.TaskRemoteDataSource>(
      () => _i592.TaskRemoteDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i259.AppointmentRepository>(
      () => _i266.AppointmentRepositoryImpl(
        gh<_i621.AppointmentRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i588.TimerRemoteDataSource>(
      () => _i588.TimerRemoteDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i381.TimerRepository>(
      () => _i825.TimerRepositoryImpl(gh<_i588.TimerRemoteDataSource>()),
    );
    gh.lazySingleton<_i584.ConfigRemoteDataSource>(
      () => _i584.ConfigRemoteDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i219.TaskListRepository>(
      () => _i924.TaskListRepositoryImpl(gh<_i813.TaskListRemoteDataSource>()),
    );
    gh.lazySingleton<_i397.WatchActiveTimerUseCase>(
      () => _i397.WatchActiveTimerUseCase(gh<_i381.TimerRepository>()),
    );
    gh.lazySingleton<_i176.CreateAppointmentUseCase>(
      () => _i176.CreateAppointmentUseCase(gh<_i259.AppointmentRepository>()),
    );
    gh.lazySingleton<_i502.DeleteAppointmentUseCase>(
      () => _i502.DeleteAppointmentUseCase(gh<_i259.AppointmentRepository>()),
    );
    gh.lazySingleton<_i897.WatchAllAppointmentsUseCase>(
      () =>
          _i897.WatchAllAppointmentsUseCase(gh<_i259.AppointmentRepository>()),
    );
    gh.lazySingleton<_i777.WatchAppointmentsForDayUseCase>(
      () => _i777.WatchAppointmentsForDayUseCase(
        gh<_i259.AppointmentRepository>(),
      ),
    );
    gh.lazySingleton<_i224.AuthRepository>(
      () => _i534.AuthRepositoryImpl(gh<_i788.AuthRemoteDataSource>()),
    );
    gh.lazySingleton<_i330.ConfigRepository>(
      () => _i62.ConfigRepositoryImpl(gh<_i584.ConfigRemoteDataSource>()),
    );
    gh.lazySingleton<_i706.TimeEntryRepository>(
      () => _i877.TimeEntryRepositoryImpl(gh<_i52.TimeEntryRemoteDataSource>()),
    );
    gh.lazySingleton<_i521.TaskRepository>(
      () => _i1011.TaskRepositoryImpl(gh<_i592.TaskRemoteDataSource>()),
    );
    gh.lazySingleton<_i488.CreateListUseCase>(
      () => _i488.CreateListUseCase(gh<_i219.TaskListRepository>()),
    );
    gh.lazySingleton<_i655.EnsureInboxExistsUseCase>(
      () => _i655.EnsureInboxExistsUseCase(gh<_i219.TaskListRepository>()),
    );
    gh.lazySingleton<_i202.RenameListUseCase>(
      () => _i202.RenameListUseCase(gh<_i219.TaskListRepository>()),
    );
    gh.lazySingleton<_i689.WatchListsUseCase>(
      () => _i689.WatchListsUseCase(gh<_i219.TaskListRepository>()),
    );
    gh.lazySingleton<_i543.RegisterAppointmentTimeUseCase>(
      () => _i543.RegisterAppointmentTimeUseCase(
        gh<_i259.AppointmentRepository>(),
        gh<_i706.TimeEntryRepository>(),
      ),
    );
    gh.lazySingleton<_i666.DeleteListUseCase>(
      () => _i666.DeleteListUseCase(
        gh<_i219.TaskListRepository>(),
        gh<_i521.TaskRepository>(),
      ),
    );
    gh.lazySingleton<_i98.SignInWithGoogleUseCase>(
      () => _i98.SignInWithGoogleUseCase(gh<_i224.AuthRepository>()),
    );
    gh.lazySingleton<_i846.SignOutUseCase>(
      () => _i846.SignOutUseCase(gh<_i224.AuthRepository>()),
    );
    gh.lazySingleton<_i1046.WatchAuthStateUseCase>(
      () => _i1046.WatchAuthStateUseCase(gh<_i224.AuthRepository>()),
    );
    gh.factory<_i427.ListManagerBloc>(
      () => _i427.ListManagerBloc(
        gh<_i689.WatchListsUseCase>(),
        gh<_i488.CreateListUseCase>(),
        gh<_i202.RenameListUseCase>(),
        gh<_i666.DeleteListUseCase>(),
      ),
    );
    gh.lazySingleton<_i949.SetAvailableMinutesUseCase>(
      () => _i949.SetAvailableMinutesUseCase(gh<_i330.ConfigRepository>()),
    );
    gh.lazySingleton<_i559.WatchConfigUseCase>(
      () => _i559.WatchConfigUseCase(gh<_i330.ConfigRepository>()),
    );
    gh.lazySingleton<_i210.StartTimerUseCase>(
      () => _i210.StartTimerUseCase(
        gh<_i381.TimerRepository>(),
        gh<_i521.TaskRepository>(),
        gh<_i259.AppointmentRepository>(),
        gh<_i706.TimeEntryRepository>(),
      ),
    );
    gh.lazySingleton<_i726.StopTimerUseCase>(
      () => _i726.StopTimerUseCase(
        gh<_i381.TimerRepository>(),
        gh<_i521.TaskRepository>(),
        gh<_i259.AppointmentRepository>(),
        gh<_i706.TimeEntryRepository>(),
      ),
    );
    gh.lazySingleton<_i1025.RegisterManualTimeUseCase>(
      () => _i1025.RegisterManualTimeUseCase(
        gh<_i521.TaskRepository>(),
        gh<_i706.TimeEntryRepository>(),
      ),
    );
    gh.lazySingleton<_i892.WatchTimeEntriesUseCase>(
      () => _i892.WatchTimeEntriesUseCase(gh<_i706.TimeEntryRepository>()),
    );
    gh.lazySingleton<_i798.MigrateTaskUseCase>(
      () => _i798.MigrateTaskUseCase(gh<_i521.TaskRepository>()),
    );
    gh.lazySingleton<_i650.AddSubtaskUseCase>(
      () => _i650.AddSubtaskUseCase(gh<_i521.TaskRepository>()),
    );
    gh.lazySingleton<_i623.CompleteTaskUseCase>(
      () => _i623.CompleteTaskUseCase(gh<_i521.TaskRepository>()),
    );
    gh.lazySingleton<_i658.CreateTaskUseCase>(
      () => _i658.CreateTaskUseCase(gh<_i521.TaskRepository>()),
    );
    gh.lazySingleton<_i162.DeleteTaskUseCase>(
      () => _i162.DeleteTaskUseCase(gh<_i521.TaskRepository>()),
    );
    gh.lazySingleton<_i43.EditTaskUseCase>(
      () => _i43.EditTaskUseCase(gh<_i521.TaskRepository>()),
    );
    gh.lazySingleton<_i213.MoveTaskUseCase>(
      () => _i213.MoveTaskUseCase(gh<_i521.TaskRepository>()),
    );
    gh.lazySingleton<_i942.RestoreTasksUseCase>(
      () => _i942.RestoreTasksUseCase(gh<_i521.TaskRepository>()),
    );
    gh.lazySingleton<_i1035.WatchTasksUseCase>(
      () => _i1035.WatchTasksUseCase(gh<_i521.TaskRepository>()),
    );
    gh.factory<_i73.ReportDetailBloc>(
      () => _i73.ReportDetailBloc(
        gh<_i1035.WatchTasksUseCase>(),
        gh<_i897.WatchAllAppointmentsUseCase>(),
        gh<_i892.WatchTimeEntriesUseCase>(),
        gh<_i689.WatchListsUseCase>(),
        gh<_i838.GetTaskReportUseCase>(),
      ),
    );
    gh.factory<_i318.ReportBloc>(
      () => _i318.ReportBloc(
        gh<_i1035.WatchTasksUseCase>(),
        gh<_i689.WatchListsUseCase>(),
        gh<_i892.WatchTimeEntriesUseCase>(),
        gh<_i67.GetListReportUseCase>(),
      ),
    );
    gh.factory<_i708.AuthBloc>(
      () => _i708.AuthBloc(
        gh<_i98.SignInWithGoogleUseCase>(),
        gh<_i846.SignOutUseCase>(),
        gh<_i1046.WatchAuthStateUseCase>(),
      ),
    );
    gh.factory<_i830.SettingsBloc>(
      () => _i830.SettingsBloc(
        gh<_i559.WatchConfigUseCase>(),
        gh<_i949.SetAvailableMinutesUseCase>(),
      ),
    );
    gh.lazySingleton<_i159.SeedFirstAccessUseCase>(
      () => _i159.SeedFirstAccessUseCase(
        gh<_i330.ConfigRepository>(),
        gh<_i658.CreateTaskUseCase>(),
      ),
    );
    gh.factory<_i35.TaskListBloc>(
      () => _i35.TaskListBloc(
        gh<_i1035.WatchTasksUseCase>(),
        gh<_i658.CreateTaskUseCase>(),
        gh<_i655.EnsureInboxExistsUseCase>(),
        gh<_i650.AddSubtaskUseCase>(),
        gh<_i27.BuildTaskTreeUseCase>(),
        gh<_i1067.GetPrioritizedLeavesUseCase>(),
        gh<_i397.WatchActiveTimerUseCase>(),
        gh<_i210.StartTimerUseCase>(),
        gh<_i726.StopTimerUseCase>(),
        gh<_i1025.RegisterManualTimeUseCase>(),
        gh<_i623.CompleteTaskUseCase>(),
        gh<_i162.DeleteTaskUseCase>(),
        gh<_i43.EditTaskUseCase>(),
        gh<_i213.MoveTaskUseCase>(),
        gh<_i689.WatchListsUseCase>(),
        gh<_i159.SeedFirstAccessUseCase>(),
        gh<_i942.RestoreTasksUseCase>(),
      ),
    );
    gh.factory<_i492.MigrationBloc>(
      () => _i492.MigrationBloc(
        gh<_i1035.WatchTasksUseCase>(),
        gh<_i842.GetPendingMigrationsUseCase>(),
        gh<_i798.MigrateTaskUseCase>(),
        gh<_i162.DeleteTaskUseCase>(),
        gh<_i43.EditTaskUseCase>(),
        gh<_i942.RestoreTasksUseCase>(),
      ),
    );
    gh.factory<_i990.AgendaBloc>(
      () => _i990.AgendaBloc(
        gh<_i777.WatchAppointmentsForDayUseCase>(),
        gh<_i176.CreateAppointmentUseCase>(),
        gh<_i502.DeleteAppointmentUseCase>(),
        gh<_i483.CheckFitsInDayUseCase>(),
        gh<_i559.WatchConfigUseCase>(),
        gh<_i1035.WatchTasksUseCase>(),
        gh<_i655.EnsureInboxExistsUseCase>(),
        gh<_i210.StartTimerUseCase>(),
        gh<_i726.StopTimerUseCase>(),
        gh<_i397.WatchActiveTimerUseCase>(),
      ),
    );
    return this;
  }
}

class _$FirebaseModule extends _i767.FirebaseModule {}
