import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_tap_entity.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/watch_lock_screen_taps_use_case.dart';
import 'package:meu_tempo/features/lock_screen/presentation/bloc/lock_screen_tap_bloc.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

import '../../fake_lock_screen_timer_gateway.dart';

const taskTap = LockScreenTapEntity(
  targetId: 't1',
  targetType: TimerTargetTypeEnum.task,
);
const appointmentTap = LockScreenTapEntity(
  targetId: 'a1',
  targetType: TimerTargetTypeEnum.appointment,
);

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeLockScreenTimerGateway gateway;

  setUp(() => gateway = FakeLockScreenTimerGateway());
  tearDown(() => gateway.dispose());

  LockScreenTapBloc build() =>
      LockScreenTapBloc(WatchLockScreenTapsUseCase(gateway));

  const wait = Duration(milliseconds: 10);

  test('initial state is Idle', () {
    final bloc = build();

    expect(bloc.state, const LockScreenTapIdle());
    bloc.close();
  });

  blocTest<LockScreenTapBloc, LockScreenTapState>(
    'a tap becomes pending',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenTapStarted());
      await flush();
      gateway.taps.add(taskTap);
    },
    wait: wait,
    expect: () => [const LockScreenTapPending(taskTap)],
  );

  blocTest<LockScreenTapBloc, LockScreenTapState>(
    'handled goes back to Idle',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenTapStarted());
      await flush();
      gateway.taps.add(taskTap);
      await flush();
      bloc.add(const LockScreenTapHandled(taskTap));
    },
    wait: wait,
    expect: () => [
      const LockScreenTapPending(taskTap),
      const LockScreenTapIdle(),
    ],
  );

  blocTest<LockScreenTapBloc, LockScreenTapState>(
    'handled of an old tap does not clear the new one',
    build: build,
    act: (bloc) async {
      bloc.add(const LockScreenTapStarted());
      await flush();
      gateway.taps.add(taskTap);
      await flush();
      gateway.taps.add(appointmentTap);
      await flush();
      bloc.add(const LockScreenTapHandled(taskTap));
    },
    wait: wait,
    expect: () => [
      const LockScreenTapPending(taskTap),
      const LockScreenTapPending(appointmentTap),
    ],
  );

  blocTest<LockScreenTapBloc, LockScreenTapState>(
    'a tap before Started is ignored',
    build: build,
    act: (_) => gateway.taps.add(taskTap),
    wait: wait,
    expect: () => <LockScreenTapState>[],
  );

  test('closing cancels the subscription', () async {
    final bloc = build()..add(const LockScreenTapStarted());
    await flush();

    await bloc.close();

    expect(gateway.taps.hasListener, isFalse);
  });
}
