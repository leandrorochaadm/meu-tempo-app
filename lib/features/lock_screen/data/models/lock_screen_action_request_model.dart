import 'package:equatable/equatable.dart';

import '../../domain/entities/lock_screen_action_enum.dart';
import '../../domain/usecases/handle_lock_screen_action_use_case.dart';
import '../background/lock_screen_channel_constants.dart';

/// Raw `handleAction` payload from the native side, already validated.
class LockScreenActionRequestModel extends Equatable {
  const LockScreenActionRequestModel({
    required this.action,
    required this.targetId,
  });

  final LockScreenActionEnum action;
  final String targetId;

  /// `null` when [raw] is not a valid payload. Never throws.
  static LockScreenActionRequestModel? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final rawAction = raw[LockScreenActionPayloadKeys.action];
    final rawTargetId = raw[LockScreenActionPayloadKeys.targetId];
    if (rawAction is! String || rawTargetId is! String) return null;
    if (rawTargetId.isEmpty) return null;
    final action = LockScreenActionEnum.fromApi(rawAction);
    if (action == null) return null;
    return LockScreenActionRequestModel(action: action, targetId: rawTargetId);
  }

  HandleLockScreenActionParams toParams(DateTime now) =>
      HandleLockScreenActionParams(
        action: action,
        targetId: targetId,
        now: now,
      );

  @override
  List<Object?> get props => [action, targetId];
}
