import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/day_config_entity.dart';

part 'day_config_model.g.dart';

@JsonSerializable(includeIfNull: false)
class DayConfigModel {
  const DayConfigModel({
    this.availableMinutesPerDay = 480,
    this.onboarded = false,
  });

  final int availableMinutesPerDay;
  final bool onboarded;

  factory DayConfigModel.fromJson(Map<String, dynamic> json) =>
      _$DayConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$DayConfigModelToJson(this);

  DayConfigEntity toEntity() => DayConfigEntity(
        availableMinutesPerDay: availableMinutesPerDay,
        onboarded: onboarded,
      );
}
