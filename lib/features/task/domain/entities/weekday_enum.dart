import 'package:json_annotation/json_annotation.dart';

/// Dia da semana de uma tarefa recorrente. O `isoValue` é o número do
/// `DateTime.weekday` (1 = segunda … 7 = domingo) e serve só à regra de calendário.
///
/// A grafia externa é o [apiValue] (nunca `.name` nem `.index`); o
/// `json_serializable` usa o mesmo campo (`valueField`).
@JsonEnum(valueField: 'apiValue')
enum WeekdayEnum {
  monday(DateTime.monday, 'monday'),
  tuesday(DateTime.tuesday, 'tuesday'),
  wednesday(DateTime.wednesday, 'wednesday'),
  thursday(DateTime.thursday, 'thursday'),
  friday(DateTime.friday, 'friday'),
  saturday(DateTime.saturday, 'saturday'),
  sunday(DateTime.sunday, 'sunday');

  const WeekdayEnum(this.isoValue, this.apiValue);

  final int isoValue;
  final String apiValue;

  /// Dia da semana de [day].
  static WeekdayEnum fromDate(DateTime day) =>
      values.firstWhere((d) => d.isoValue == day.weekday);

  /// Converte o valor externo. Ausente ou desconhecido → `null`.
  static WeekdayEnum? fromApi(String? raw) {
    for (final weekday in values) {
      if (weekday.apiValue == raw) return weekday;
    }
    return null;
  }
}
