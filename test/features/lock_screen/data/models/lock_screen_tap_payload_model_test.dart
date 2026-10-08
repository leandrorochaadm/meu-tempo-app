import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/lock_screen/data/models/lock_screen_tap_payload_model.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_tap_entity.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

void main() {
  test('lê o toque de um compromisso', () {
    final model = LockScreenTapPayloadModel.fromMap({
      'targetType': 'appointment',
      'targetId': 'a1',
    });

    expect(model?.targetType, TimerTargetTypeEnum.appointment);
    expect(model?.targetId, 'a1');
  });

  test('entrada inválida devolve null', () {
    final invalid = <Object?>[
      null,
      ['task', 't1'],
      {'targetType': 'x', 'targetId': 't1'},
      {'targetType': 'task'},
      {'targetType': 'task', 'targetId': ''},
      {'targetType': 'task', 'targetId': 7},
    ];

    for (final raw in invalid) {
      expect(LockScreenTapPayloadModel.fromMap(raw), isNull, reason: '$raw');
    }
  });

  test('toEntity converte para a entidade', () {
    final model = LockScreenTapPayloadModel.fromMap({
      'targetType': 'appointment',
      'targetId': 'a1',
    })!;

    expect(
      model.toEntity(),
      const LockScreenTapEntity(
        targetId: 'a1',
        targetType: TimerTargetTypeEnum.appointment,
      ),
    );
  });
}
