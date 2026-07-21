part of 'time_entry_bloc.dart';

sealed class TimeEntryEvent extends Equatable {
  const TimeEntryEvent();

  @override
  List<Object?> get props => const [];
}

/// Inicializa a tela: passa a escutar os registros da folha.
class TimeEntryStarted extends TimeEntryEvent {
  const TimeEntryStarted({required this.targetId, required this.listId});
  final String targetId;
  final String listId;

  @override
  List<Object?> get props => [targetId, listId];
}

/// Emitido internamente quando o stream de registros atualiza.
class _TimeEntriesUpdated extends TimeEntryEvent {
  const _TimeEntriesUpdated(this.result);
  final Either<Failure, List<TimeEntryEntity>> result;

  @override
  List<Object?> get props => [result];
}

/// Adiciona um novo registro manual de tempo.
class TimeEntryAdded extends TimeEntryEvent {
  const TimeEntryAdded({required this.minutes, required this.occurredAt});
  final int minutes;
  final DateTime occurredAt;

  @override
  List<Object?> get props => [minutes, occurredAt];
}

/// Edita minutos/data de um registro existente.
class TimeEntryEdited extends TimeEntryEvent {
  const TimeEntryEdited({
    required this.original,
    required this.minutes,
    required this.occurredAt,
  });
  final TimeEntryEntity original;
  final int minutes;
  final DateTime occurredAt;

  @override
  List<Object?> get props => [original, minutes, occurredAt];
}

/// Exclui um registro (com desfazer via snackbar).
class TimeEntryDeleted extends TimeEntryEvent {
  const TimeEntryDeleted(this.entry);
  final TimeEntryEntity entry;

  @override
  List<Object?> get props => [entry];
}

/// Desfaz a última exclusão, recriando o registro (re-soma ao acumulado).
class TimeEntryUndoRequested extends TimeEntryEvent {
  const TimeEntryUndoRequested();
}
