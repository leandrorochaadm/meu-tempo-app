import 'package:json_annotation/json_annotation.dart';

/// Dia da semana de uma tarefa recorrente. O `isoValue` é o número do
/// `DateTime.weekday` (1 = segunda … 7 = domingo) e serve só à regra de calendário.
///
/// Serializado por `.name` (nunca `.index`) — estável ao reordenar.
@JsonEnum()
enum WeekdayEnum {
  monday(DateTime.monday),
  tuesday(DateTime.tuesday),
  wednesday(DateTime.wednesday),
  thursday(DateTime.thursday),
  friday(DateTime.friday),
  saturday(DateTime.saturday),
  sunday(DateTime.sunday);

  const WeekdayEnum(this.isoValue);

  final int isoValue;

  /// Dia da semana de [day].
  static WeekdayEnum fromDate(DateTime day) =>
      values.firstWhere((d) => d.isoValue == day.weekday);
}
