import 'package:equatable/equatable.dart';

/// Configuração do dia do usuário. Por ora, só as horas disponíveis para
/// planejar ("cabe no dia").
class DayConfigEntity extends Equatable {
  const DayConfigEntity({
    this.availableMinutesPerDay = 480, // 8h padrão
    this.onboarded = false,
  });

  final int availableMinutesPerDay;

  /// Marca se o usuário já passou pelo primeiro acesso (tarefa-exemplo semeada).
  final bool onboarded;

  @override
  List<Object?> get props => [availableMinutesPerDay, onboarded];
}
