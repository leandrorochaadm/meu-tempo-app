import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../domain/entities/day_config_entity.dart';

part 'day_config_model.g.dart';

@JsonSerializable(includeIfNull: true, fieldRename: FieldRename.snake)
class DayConfigModel {
  const DayConfigModel({
    this.availableMinutesPerDay = 480,
    this.onboarded = false,
  });

  final int availableMinutesPerDay;
  final bool onboarded;

  factory DayConfigModel.fromRecord(RecordModel record) =>
      DayConfigModel.fromJson(record.data);

  factory DayConfigModel.fromJson(Map<String, dynamic> json) =>
      _$DayConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$DayConfigModelToJson(this);

  DayConfigEntity toEntity() => DayConfigEntity(
    availableMinutesPerDay: availableMinutesPerDay,
    onboarded: onboarded,
  );
}
