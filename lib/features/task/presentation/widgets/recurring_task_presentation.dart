import '../../domain/entities/recurring_task_entity.dart';
import '../../domain/entities/weekday_enum.dart';
import 'weekday_presentation.dart';

/// Apresentação do modelo recorrente. Só exibição; "todo dia" e "sem dia fixo"
/// são getters da entity (`isEveryDay`/`isScheduled`).
extension RecurringSchedulePresentationX on RecurringTaskEntity {
  /// Resumo dos dias na ordem seg→dom (o `Set` da entity não garante ordem).
  String get scheduleLabel => switch ((isEveryDay, isScheduled)) {
    (true, _) => 'Todo dia',
    (false, true) =>
      WeekdayEnum.values
          .where(weekdays.contains)
          .map((d) => d.label)
          .join(' · '),
    (false, false) => 'Sem dia fixo',
  };
}
