import 'package:equatable/equatable.dart';

import '../../../task/domain/entities/timer_target_type_enum.dart';
import '../../domain/entities/lock_screen_tap_entity.dart';
import '../background/lock_screen_channel_constants.dart';

/// Tap event sent by the native side (`{targetType, targetId}`).
class LockScreenTapPayloadModel extends Equatable {
  const LockScreenTapPayloadModel({
    required this.targetType,
    required this.targetId,
  });

  final TimerTargetTypeEnum targetType;
  final String targetId;

  /// Invalid input (not a map, unknown type, empty id) returns `null`.
  static LockScreenTapPayloadModel? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final type = raw[LockScreenTimerPayloadKeys.targetType];
    final id = raw[LockScreenTimerPayloadKeys.targetId];
    if (type is! String || id is! String || id.isEmpty) return null;
    final targetType = TimerTargetTypeEnum.fromApi(type);
    if (targetType == null) return null;
    return LockScreenTapPayloadModel(targetType: targetType, targetId: id);
  }

  LockScreenTapEntity toEntity() =>
      LockScreenTapEntity(targetId: targetId, targetType: targetType);

  @override
  List<Object?> get props => [targetType, targetId];
}
