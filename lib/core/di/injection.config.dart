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
import 'package:meu_tempo/features/list/data/datasources/task_list_remote_data_source.dart'
    as _i813;
import 'package:meu_tempo/features/list/data/repositories/task_list_repository_impl.dart'
    as _i924;
import 'package:meu_tempo/features/list/domain/repositories/task_list_repository.dart'
    as _i219;
import 'package:meu_tempo/features/list/domain/usecases/ensure_inbox_exists_use_case.dart'
    as _i655;
import 'package:meu_tempo/features/list/domain/usecases/watch_lists_use_case.dart'
    as _i689;
import 'package:meu_tempo/features/task/data/datasources/task_remote_data_source.dart'
    as _i592;
import 'package:meu_tempo/features/task/data/datasources/timer_remote_data_source.dart'
    as _i588;
import 'package:meu_tempo/features/task/data/repositories/task_repository_impl.dart'
    as _i1011;
import 'package:meu_tempo/features/task/data/repositories/timer_repository_impl.dart'
    as _i825;
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart'
    as _i521;
import 'package:meu_tempo/features/task/domain/repositories/timer_repository.dart'
    as _i381;
import 'package:meu_tempo/features/task/domain/usecases/add_subtask_use_case.dart'
    as _i650;
import 'package:meu_tempo/features/task/domain/usecases/build_task_tree_use_case.dart'
    as _i27;
import 'package:meu_tempo/features/task/domain/usecases/create_task_use_case.dart'
    as _i658;
import 'package:meu_tempo/features/task/domain/usecases/register_manual_time_use_case.dart'
    as _i1025;
import 'package:meu_tempo/features/task/domain/usecases/start_timer_use_case.dart'
    as _i210;
import 'package:meu_tempo/features/task/domain/usecases/stop_timer_use_case.dart'
    as _i726;
import 'package:meu_tempo/features/task/domain/usecases/watch_active_timer_use_case.dart'
    as _i397;
import 'package:meu_tempo/features/task/domain/usecases/watch_tasks_use_case.dart'
    as _i1035;
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
    gh.lazySingleton<_i27.BuildTaskTreeUseCase>(
      () => const _i27.BuildTaskTreeUseCase(),
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
    gh.lazySingleton<_i592.TaskRemoteDataSource>(
      () => _i592.TaskRemoteDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i59.FirebaseAuth>(),
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
    gh.lazySingleton<_i219.TaskListRepository>(
      () => _i924.TaskListRepositoryImpl(gh<_i813.TaskListRemoteDataSource>()),
    );
    gh.lazySingleton<_i397.WatchActiveTimerUseCase>(
      () => _i397.WatchActiveTimerUseCase(gh<_i381.TimerRepository>()),
    );
    gh.lazySingleton<_i224.AuthRepository>(
      () => _i534.AuthRepositoryImpl(gh<_i788.AuthRemoteDataSource>()),
    );
    gh.lazySingleton<_i521.TaskRepository>(
      () => _i1011.TaskRepositoryImpl(gh<_i592.TaskRemoteDataSource>()),
    );
    gh.lazySingleton<_i655.EnsureInboxExistsUseCase>(
      () => _i655.EnsureInboxExistsUseCase(gh<_i219.TaskListRepository>()),
    );
    gh.lazySingleton<_i689.WatchListsUseCase>(
      () => _i689.WatchListsUseCase(gh<_i219.TaskListRepository>()),
    );
    gh.lazySingleton<_i210.StartTimerUseCase>(
      () => _i210.StartTimerUseCase(
        gh<_i381.TimerRepository>(),
        gh<_i521.TaskRepository>(),
      ),
    );
    gh.lazySingleton<_i726.StopTimerUseCase>(
      () => _i726.StopTimerUseCase(
        gh<_i381.TimerRepository>(),
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
    gh.lazySingleton<_i1025.RegisterManualTimeUseCase>(
      () => _i1025.RegisterManualTimeUseCase(gh<_i521.TaskRepository>()),
    );
    gh.lazySingleton<_i650.AddSubtaskUseCase>(
      () => _i650.AddSubtaskUseCase(gh<_i521.TaskRepository>()),
    );
    gh.lazySingleton<_i658.CreateTaskUseCase>(
      () => _i658.CreateTaskUseCase(gh<_i521.TaskRepository>()),
    );
    gh.lazySingleton<_i1035.WatchTasksUseCase>(
      () => _i1035.WatchTasksUseCase(gh<_i521.TaskRepository>()),
    );
    gh.factory<_i708.AuthBloc>(
      () => _i708.AuthBloc(
        gh<_i98.SignInWithGoogleUseCase>(),
        gh<_i846.SignOutUseCase>(),
        gh<_i1046.WatchAuthStateUseCase>(),
      ),
    );
    gh.factory<_i35.TaskListBloc>(
      () => _i35.TaskListBloc(
        gh<_i1035.WatchTasksUseCase>(),
        gh<_i658.CreateTaskUseCase>(),
        gh<_i655.EnsureInboxExistsUseCase>(),
        gh<_i650.AddSubtaskUseCase>(),
        gh<_i27.BuildTaskTreeUseCase>(),
        gh<_i397.WatchActiveTimerUseCase>(),
        gh<_i210.StartTimerUseCase>(),
        gh<_i726.StopTimerUseCase>(),
        gh<_i1025.RegisterManualTimeUseCase>(),
      ),
    );
    return this;
  }
}

class _$FirebaseModule extends _i767.FirebaseModule {}
