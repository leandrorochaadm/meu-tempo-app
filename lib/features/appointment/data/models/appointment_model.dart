import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../../../core/utils/calendar_date_codec.dart';
import '../../domain/entities/appointment_entity.dart';

part 'appointment_model.g.dart';

@JsonSerializable(includeIfNull: true, fieldRename: FieldRename.snake)
class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.title,
    required this.listId,
    required this.date,
    required this.startMinute,
    required this.durationMinutes,
    this.spentMinutes = 0,
    this.isDone = false,
  });

  @JsonKey(includeToJson: false)
  final String id;
  final String title;
  final String listId;
  @CalendarDateConverter()
  final DateTime? date;
  final int startMinute;
  final int durationMinutes;
  final int spentMinutes;

  /// Registro sem o campo é lido como não concluído (default do construtor).
  final bool isDone;

  factory AppointmentModel.fromRecord(RecordModel record) =>
      AppointmentModel.fromJson({...record.data, PbFields.id: record.id});

  factory AppointmentModel.fromJson(Map<String, dynamic> json) =>
      _$AppointmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$AppointmentModelToJson(this);

  AppointmentEntity toEntity() => AppointmentEntity(
    id: id,
    title: title,
    listId: listId,
    date: date ?? DateTime.fromMillisecondsSinceEpoch(0),
    startMinute: startMinute,
    durationMinutes: durationMinutes,
    spentMinutes: spentMinutes,
    isDone: isDone,
  );

  factory AppointmentModel.fromEntity(AppointmentEntity e) => AppointmentModel(
    id: e.id,
    title: e.title,
    listId: e.listId,
    date: e.date,
    startMinute: e.startMinute,
    durationMinutes: e.durationMinutes,
    spentMinutes: e.spentMinutes,
    isDone: e.isDone,
  );
}
