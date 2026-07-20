import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/appointment_entity.dart';

part 'appointment_model.g.dart';

@JsonSerializable(includeIfNull: false)
class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.title,
    required this.listId,
    required this.date,
    required this.startMinute,
    required this.durationMinutes,
    this.spentMinutes = 0,
  });

  @JsonKey(includeToJson: false)
  final String id;
  final String title;
  final String listId;
  @TimestampConverter()
  final DateTime? date;
  final int startMinute;
  final int durationMinutes;
  final int spentMinutes;

  factory AppointmentModel.fromDoc(String id, Map<String, dynamic> data) =>
      AppointmentModel.fromJson({...data, 'id': id});

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
      );

  factory AppointmentModel.fromEntity(AppointmentEntity e) => AppointmentModel(
        id: e.id,
        title: e.title,
        listId: e.listId,
        date: e.date,
        startMinute: e.startMinute,
        durationMinutes: e.durationMinutes,
        spentMinutes: e.spentMinutes,
      );
}
