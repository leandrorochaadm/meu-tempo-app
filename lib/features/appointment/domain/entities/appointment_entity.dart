import 'package:equatable/equatable.dart';

/// Compromisso com data, hora de início e duração (fim = início + duração).
/// Tem registro de tempo real e pertence a uma lista. Aparece na agenda do dia.
class AppointmentEntity extends Equatable {
  const AppointmentEntity({
    required this.id,
    required this.title,
    required this.listId,
    required this.date,
    required this.startMinute,
    required this.durationMinutes,
    this.spentMinutes = 0,
  });

  final String id;
  final String title;
  final String listId;

  /// Dia do compromisso (meia-noite).
  final DateTime date;

  /// Início em minutos a partir da meia-noite (ex.: 15h = 900).
  final int startMinute;
  final int durationMinutes;
  final int spentMinutes;

  int get endMinute => startMinute + durationMinutes;

  @override
  List<Object?> get props =>
      [id, title, listId, date, startMinute, durationMinutes, spentMinutes];
}
