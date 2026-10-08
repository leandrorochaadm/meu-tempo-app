import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/lock_screen/data/background/lock_screen_action_reply_enum.dart';
import 'package:meu_tempo/features/lock_screen/data/background/lock_screen_channel_constants.dart';
import 'package:meu_tempo/features/lock_screen/data/models/lock_screen_action_reply_model.dart';
import 'package:meu_tempo/features/lock_screen/data/models/lock_screen_timer_payload_model.dart';

void main() {
  test('show leva o cronômetro', () {
    const payload = LockScreenTimerPayloadModel(
      targetId: 't1',
      targetType: 'task',
      title: 'Tela de login',
      listName: 'Trabalho',
      status: 'running',
      clockBaseEpochMillis: 1,
      elapsedMillis: 2,
      actions: ['pause', 'stop_confirmed'],
      stopConfirmationWindowMillis: 5000,
    );

    final map = const LockScreenActionReplyModel.show(payload).toMap();

    expect(
      map[LockScreenReplyKeys.reply],
      LockScreenActionReplyEnum.show.apiValue,
    );
    expect(map[LockScreenReplyKeys.timer], payload.toMap());
  });

  test('clear e unchanged não levam cronômetro', () {
    final clear = const LockScreenActionReplyModel.clear().toMap();
    final unchanged = const LockScreenActionReplyModel.unchanged().toMap();

    expect(
      clear[LockScreenReplyKeys.reply],
      LockScreenActionReplyEnum.clear.apiValue,
    );
    expect(clear.containsKey(LockScreenReplyKeys.timer), isFalse);
    expect(
      unchanged[LockScreenReplyKeys.reply],
      LockScreenActionReplyEnum.unchanged.apiValue,
    );
    expect(unchanged.containsKey(LockScreenReplyKeys.timer), isFalse);
  });
}
