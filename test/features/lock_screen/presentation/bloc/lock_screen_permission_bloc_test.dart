import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_permission_status_enum.dart';
import 'package:meu_tempo/features/lock_screen/domain/lock_screen_failures.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/get_lock_screen_permission_status_use_case.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/open_notification_settings_use_case.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/watch_lock_screen_permission_warnings_use_case.dart';
import 'package:meu_tempo/features/lock_screen/presentation/bloc/lock_screen_permission_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../fake_lock_screen_timer_gateway.dart';

class _MockWatchWarnings extends Mock
    implements WatchLockScreenPermissionWarningsUseCase {}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _MockWatchWarnings watchWarnings;
  late FakeLockScreenTimerGateway gateway;
  late List<StreamController<Either<Failure, Unit>>> sources;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    watchWarnings = _MockWatchWarnings();
    gateway = FakeLockScreenTimerGateway()
      ..permissionResult = const Right(LockScreenPermissionStatusEnum.denied);
    sources = [];
    when(() => watchWarnings(any())).thenAnswer((_) {
      final source = StreamController<Either<Failure, Unit>>();
      sources.add(source);
      return source.stream;
    });
  });

  tearDown(() async {
    for (final s in sources) {
      await s.close();
    }
    await gateway.dispose();
  });

  LockScreenPermissionBloc build() => LockScreenPermissionBloc(
    watchWarnings,
    GetLockScreenPermissionStatusUseCase(gateway),
    OpenNotificationSettingsUseCase(gateway),
  );

  const wait = Duration(milliseconds: 10);

  test('initial state: no banner, no subscription', () {
    final bloc = build();

    expect(bloc.state, const LockScreenPermissionBannerHidden());
    verifyNever(() => watchWarnings(any()));
    bloc.close();
  });

  blocTest<LockScreenPermissionBloc, LockScreenPermissionState>(
    'a warning shows the banner',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenPermissionStarted());
      await flush();
      sources.last.add(const Right(unit));
    },
    wait: wait,
    expect: () => [const LockScreenPermissionBannerVisible()],
  );

  blocTest<LockScreenPermissionBloc, LockScreenPermissionState>(
    'failure reading the permission does not show it',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenPermissionStarted());
      await flush();
      sources.single.add(const Left(LockScreenPlatformFailure()));
    },
    wait: wait,
    expect: () => <LockScreenPermissionState>[],
  );

  blocTest<LockScreenPermissionBloc, LockScreenPermissionState>(
    '"Agora não" closes the banner',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenPermissionStarted());
      await flush();
      sources.last.add(const Right(unit));
      await flush();
      bloc.add(const LockScreenPermissionBannerDismissed());
    },
    wait: wait,
    expect: () => [
      const LockScreenPermissionBannerVisible(),
      const LockScreenPermissionBannerHidden(),
    ],
  );

  blocTest<LockScreenPermissionBloc, LockScreenPermissionState>(
    'the banner comes back on the next warning',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenPermissionStarted());
      await flush();
      sources.last.add(const Right(unit));
      await flush();
      bloc.add(const LockScreenPermissionBannerDismissed());
      await flush();
      sources.last.add(const Right(unit));
    },
    wait: wait,
    expect: () => [
      const LockScreenPermissionBannerVisible(),
      const LockScreenPermissionBannerHidden(),
      const LockScreenPermissionBannerVisible(),
    ],
  );

  blocTest<LockScreenPermissionBloc, LockScreenPermissionState>(
    '"Abrir Ajustes" calls the phone and keeps the banner',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenPermissionStarted());
      await flush();
      sources.last.add(const Right(unit));
      await flush();
      bloc.add(const LockScreenPermissionSettingsRequested());
    },
    wait: wait,
    expect: () => [const LockScreenPermissionBannerVisible()],
    verify: (_) => expect(gateway.openSettingsCalls, 1),
  );

  blocTest<LockScreenPermissionBloc, LockScreenPermissionState>(
    'failure opening the settings changes nothing',
    build: () {
      gateway.openSettingsResult = const Left(LockScreenPlatformFailure());
      return build();
    },
    act: (bloc) async {
      bloc.add(const LockScreenPermissionStarted());
      await flush();
      sources.last.add(const Right(unit));
      await flush();
      bloc.add(const LockScreenPermissionSettingsRequested());
    },
    wait: wait,
    expect: () => [const LockScreenPermissionBannerVisible()],
  );

  blocTest<LockScreenPermissionBloc, LockScreenPermissionState>(
    'coming back from the settings with notifications on hides the banner',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenPermissionStarted());
      await flush();
      sources.last.add(const Right(unit));
      await flush();
      gateway.permissionResult = const Right(
        LockScreenPermissionStatusEnum.granted,
      );
      bloc.add(const LockScreenPermissionAppResumed());
    },
    wait: wait,
    expect: () => [
      const LockScreenPermissionBannerVisible(),
      const LockScreenPermissionBannerHidden(),
    ],
    verify: (_) {
      expect(sources.length, 2);
      expect(sources[0].hasListener, isFalse);
    },
  );

  blocTest<LockScreenPermissionBloc, LockScreenPermissionState>(
    'coming back with notifications still off keeps the banner',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenPermissionStarted());
      await flush();
      sources.last.add(const Right(unit));
      await flush();
      bloc.add(const LockScreenPermissionAppResumed());
    },
    wait: wait,
    expect: () => [const LockScreenPermissionBannerVisible()],
    verify: (_) => expect(gateway.permissionChecks, 1),
  );

  blocTest<LockScreenPermissionBloc, LockScreenPermissionState>(
    'coming back with a failed read keeps the banner',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenPermissionStarted());
      await flush();
      sources.last.add(const Right(unit));
      await flush();
      gateway.permissionResult = const Left(LockScreenPlatformFailure());
      bloc.add(const LockScreenPermissionAppResumed());
    },
    wait: wait,
    expect: () => [const LockScreenPermissionBannerVisible()],
  );

  blocTest<LockScreenPermissionBloc, LockScreenPermissionState>(
    'coming back with the banner hidden does not read the permission',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenPermissionStarted());
      await flush();
      bloc.add(const LockScreenPermissionAppResumed());
    },
    wait: wait,
    expect: () => <LockScreenPermissionState>[],
    verify: (_) {
      expect(gateway.permissionChecks, 0);
      expect(sources.length, 2);
    },
  );

  blocTest<LockScreenPermissionBloc, LockScreenPermissionState>(
    'foreground while signed out does nothing',
    build: build,
    act: (bloc) => bloc.add(const LockScreenPermissionAppResumed()),
    wait: wait,
    expect: () => <LockScreenPermissionState>[],
    verify: (_) => verifyNever(() => watchWarnings(any())),
  );

  blocTest<LockScreenPermissionBloc, LockScreenPermissionState>(
    'signing out cancels and hides',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenPermissionStarted());
      await flush();
      sources.last.add(const Right(unit));
      await flush();
      bloc.add(const LockScreenPermissionStopped());
    },
    wait: wait,
    expect: () => [
      const LockScreenPermissionBannerVisible(),
      const LockScreenPermissionBannerHidden(),
    ],
    verify: (_) => expect(sources.single.hasListener, isFalse),
  );

  blocTest<LockScreenPermissionBloc, LockScreenPermissionState>(
    'a late warning from an old subscription is ignored',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenPermissionStarted());
      await flush();
      bloc.add(const LockScreenPermissionStopped());
      sources.single.add(const Right(unit));
      await flush();
    },
    wait: wait,
    // Only the Stopped hides; the late warning never shows the banner.
    expect: () => [const LockScreenPermissionBannerHidden()],
  );

  test('closing the Bloc cancels the stream', () async {
    final bloc = build()..add(const LockScreenPermissionStarted());
    await flush();

    await bloc.close();

    expect(sources.single.hasListener, isFalse);
  });
}
