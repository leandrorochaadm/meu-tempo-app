import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/importance_enum.dart';
import '../../domain/entities/recurring_task_entity.dart';
import '../../domain/entities/weekday_enum.dart';

part 'recurring_task_model.g.dart';

@JsonSerializable(includeIfNull: false)
class RecurringTaskModel {
  const RecurringTaskModel({
    required this.id,
    required this.title,
    required this.listId,
    required this.estimatedMinutes,
    required this.importance,
    this.weekdays = const [],
    this.createdAt,
    this.lastGeneratedOn,
  });

  @JsonKey(includeToJson: false) // id vem do doc.id
  final String id;
  final String title;
  final String listId;
  final int estimatedMinutes;
  final ImportanceEnum importance;

  /// Gravado por nome (`monday`…); lista vazia = "sem dia fixo" (R2).
  final List<WeekdayEnum> weekdays;
  @TimestampConverter()
  final DateTime? createdAt;

  /// Meia-noite local do dia da última geração; só o `claimGeneration` grava.
  @TimestampConverter()
  final DateTime? lastGeneratedOn;

  factory RecurringTaskModel.fromDoc(String id, Map<String, dynamic> data) =>
      RecurringTaskModel.fromJson({...data, 'id': id});

  factory RecurringTaskModel.fromJson(Map<String, dynamic> json) =>
      _$RecurringTaskModelFromJson(json);

  Map<String, dynamic> toJson() => _$RecurringTaskModelToJson(this);

  RecurringTaskEntity toEntity() => RecurringTaskEntity(
    id: id,
    title: title,
    listId: listId,
    estimatedMinutes: estimatedMinutes,
    importance: importance,
    weekdays: weekdays.toSet(),
    createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    lastGeneratedOn: lastGeneratedOn,
  );

  factory RecurringTaskModel.fromEntity(RecurringTaskEntity e) =>
      RecurringTaskModel(
        id: e.id,
        title: e.title,
        listId: e.listId,
        estimatedMinutes: e.estimatedMinutes,
        importance: e.importance,
        // Sempre na ordem seg→dom, sem depender da ordem do Set.
        weekdays: WeekdayEnum.values.where(e.weekdays.contains).toList(),
        createdAt: e.createdAt,
        lastGeneratedOn: e.lastGeneratedOn,
      );
}
