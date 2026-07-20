import 'package:equatable/equatable.dart';

/// Linha do relatório por lista: tempo estimado × tempo real das folhas.
class ListReportRow extends Equatable {
  const ListReportRow({
    required this.listId,
    required this.listName,
    required this.estimatedMinutes,
    required this.spentMinutes,
  });

  final String listId;
  final String listName;
  final int estimatedMinutes;
  final int spentMinutes;

  @override
  List<Object?> get props => [listId, listName, estimatedMinutes, spentMinutes];
}
