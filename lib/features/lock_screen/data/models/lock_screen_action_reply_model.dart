import 'package:equatable/equatable.dart';

import '../background/lock_screen_action_reply_enum.dart';
import '../background/lock_screen_channel_constants.dart';
import 'lock_screen_timer_payload_model.dart';

/// Reply to a `handleAction`: what the native side must do.
class LockScreenActionReplyModel extends Equatable {
  const LockScreenActionReplyModel.show(LockScreenTimerPayloadModel this.timer)
    : reply = LockScreenActionReplyEnum.show;

  const LockScreenActionReplyModel.clear()
    : reply = LockScreenActionReplyEnum.clear,
      timer = null;

  const LockScreenActionReplyModel.unchanged()
    : reply = LockScreenActionReplyEnum.unchanged,
      timer = null;

  final LockScreenActionReplyEnum reply;
  final LockScreenTimerPayloadModel? timer;

  Map<String, Object?> toMap() {
    final timer = this.timer;
    return {
      LockScreenReplyKeys.reply: reply.apiValue,
      if (timer != null) LockScreenReplyKeys.timer: timer.toMap(),
    };
  }

  @override
  List<Object?> get props => [reply, timer];
}
