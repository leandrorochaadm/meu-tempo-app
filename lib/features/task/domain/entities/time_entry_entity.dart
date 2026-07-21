import 'package:equatable/equatable.dart';

import 'time_entry_origin_enum.dart';
import 'timer_target_type_enum.dart';

/// Registro de tempo **datado** de uma folha ou compromisso. É o histórico que
/// permite o relatório filtrar por período (dia/semana/mês). O `spentMinutes`
/// no doc da folha/compromisso continua sendo o acumulado total (não substitui).
class TimeEntryEntity extends Equatable {
  const TimeEntryEntity({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.listId,
    required this.minutes,
    required this.origin,
    required this.occurredAt,
  });

  final String id;
  final String targetId;
  final TimerTargetTypeEnum targetType;
  final String listId;
  final int minutes;
  final TimeEntryOriginEnum origin;
  final DateTime occurredAt;

  @override
  List<Object?> get props =>
      [id, targetId, targetType, listId, minutes, origin, occurredAt];
}
