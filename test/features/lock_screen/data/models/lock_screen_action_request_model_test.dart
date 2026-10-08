import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/lock_screen/data/models/lock_screen_action_request_model.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_action_enum.dart';
import 'package:meu_tempo/features/lock_screen/domain/usecases/handle_lock_screen_action_use_case.dart';

void main() {
  test('lê ação e alvo', () {
    final model = LockScreenActionRequestModel.fromMap({
      'action': 'stop_confirmed',
      'targetId': 'a1',
    });

    expect(
      model,
      const LockScreenActionRequestModel(
        action: LockScreenActionEnum.stopConfirmed,
        targetId: 'a1',
      ),
    );
  });

  test('payload inválido devolve null', () {
    final invalid = <Object?>[
      null,
      'pause',
      {'action': 'stop', 'targetId': 'a1'},
      {'action': 1, 'targetId': 'a1'},
      {'action': 'pause'},
      {'action': 'pause', 'targetId': ''},
      {'action': 'pause', 'targetId': 7},
    ];

    for (final raw in invalid) {
      expect(LockScreenActionRequestModel.fromMap(raw), isNull, reason: '$raw');
    }
  });

  test('toParams leva ação, alvo e instante', () {
    final now = DateTime(2026, 10, 7, 10, 5);
    const model = LockScreenActionRequestModel(
      action: LockScreenActionEnum.resume,
      targetId: 't1',
    );

    expect(
      model.toParams(now),
      HandleLockScreenActionParams(
        action: LockScreenActionEnum.resume,
        targetId: 't1',
        now: now,
      ),
    );
  });
}
