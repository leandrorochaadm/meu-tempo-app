import '../../domain/entities/weekday_enum.dart';

/// Apresentação do dia da semana: rótulos em PT. Só exibição; a regra "vence
/// hoje" é `RecurringTaskEntity.isDueOn`.
extension WeekdayPresentationX on WeekdayEnum {
  /// Inicial do dia (círculo do seletor). Repete letras (Q, S): quem lê o dia
  /// por acessibilidade usa [label].
  String get shortLabel => switch (this) {
    WeekdayEnum.monday => 'S',
    WeekdayEnum.tuesday => 'T',
    WeekdayEnum.wednesday => 'Q',
    WeekdayEnum.thursday => 'Q',
    WeekdayEnum.friday => 'S',
    WeekdayEnum.saturday => 'S',
    WeekdayEnum.sunday => 'D',
  };

  String get label => switch (this) {
    WeekdayEnum.monday => 'Seg',
    WeekdayEnum.tuesday => 'Ter',
    WeekdayEnum.wednesday => 'Qua',
    WeekdayEnum.thursday => 'Qui',
    WeekdayEnum.friday => 'Sex',
    WeekdayEnum.saturday => 'Sáb',
    WeekdayEnum.sunday => 'Dom',
  };
}
