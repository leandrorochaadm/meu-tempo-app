import 'package:equatable/equatable.dart';

import 'importance_enum.dart';
import 'weekday_enum.dart';

/// Modelo de tarefa recorrente (H15). Sempre folha: não tem filhas (R1).
///
/// [weekdays] vazio = "sem dia fixo": só vira tarefa pelo botão "Adicionar hoje" (R2).
class RecurringTaskEntity extends Equatable {
  RecurringTaskEntity({
    required this.id,
    required this.title,
    required this.listId,
    required this.estimatedMinutes,
    required this.importance,
    required Set<WeekdayEnum> weekdays,
    required this.createdAt,
    this.lastGeneratedOn,
  }) : weekdays = Set.unmodifiable(weekdays);

  final String id;
  final String title;
  final String listId;
  final int estimatedMinutes;
  final ImportanceEnum importance;
  final Set<WeekdayEnum> weekdays;
  final DateTime createdAt;

  /// Dia da última geração (automática ou manual no dia agendado). `null` = nunca gerou.
  final DateTime? lastGeneratedOn;

  /// Tem pelo menos um dia marcado.
  bool get isScheduled => weekdays.isNotEmpty;

  /// Repete todos os dias da semana.
  bool get isEveryDay => weekdays.length == WeekdayEnum.values.length;

  /// O modelo vence em [day] (precisa ter dia marcado).
  bool isDueOn(DateTime day) =>
      isScheduled && weekdays.contains(WeekdayEnum.fromDate(day));

  /// Já gerou tarefa em [day] (compara só ano, mês e dia).
  bool wasGeneratedOn(DateTime day) {
    final last = lastGeneratedOn;
    return last != null &&
        last.year == day.year &&
        last.month == day.month &&
        last.day == day.day;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    listId,
    estimatedMinutes,
    importance,
    weekdays,
    createdAt,
    lastGeneratedOn,
  ];
}
