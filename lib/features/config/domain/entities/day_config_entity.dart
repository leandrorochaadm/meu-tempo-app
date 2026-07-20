import 'package:equatable/equatable.dart';

/// Configuração do dia do usuário. Por ora, só as horas disponíveis para
/// planejar ("cabe no dia").
class DayConfigEntity extends Equatable {
  const DayConfigEntity({this.availableMinutesPerDay = 480}); // 8h padrão

  final int availableMinutesPerDay;

  @override
  List<Object?> get props => [availableMinutesPerDay];
}
