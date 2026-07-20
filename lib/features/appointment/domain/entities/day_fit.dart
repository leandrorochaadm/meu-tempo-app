import 'package:equatable/equatable.dart';

/// Resultado do "cabe no dia": quanto foi planejado × quanto há disponível.
class DayFit extends Equatable {
  const DayFit({
    required this.plannedMinutes,
    required this.availableMinutes,
  });

  final int plannedMinutes;
  final int availableMinutes;

  bool get fits => plannedMinutes <= availableMinutes;
  int get overflowMinutes =>
      fits ? 0 : plannedMinutes - availableMinutes;

  @override
  List<Object?> get props => [plannedMinutes, availableMinutes];
}
