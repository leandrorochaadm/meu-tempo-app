import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/pb_schema.dart';
import 'package:meu_tempo/features/config/data/models/day_config_model.dart';
import 'package:pocketbase/pocketbase.dart';

void main() {
  test('fromRecord maps the PocketBase payload', () {
    final model = DayConfigModel.fromRecord(
      RecordModel.fromJson({
        'id': 'cfg1',
        'user': 'user-a',
        'available_minutes_per_day': 300,
        'onboarded': true,
      }),
    );
    expect(model.availableMinutesPerDay, 300);
    expect(model.onboarded, isTrue);
  });

  test('missing fields use the defaults', () {
    final model = DayConfigModel.fromRecord(
      RecordModel.fromJson({'id': 'cfg1'}),
    );
    expect(model.availableMinutesPerDay, 480);
    expect(model.onboarded, isFalse);
  });

  test('toJson has exactly the two fields', () {
    expect(const DayConfigModel().toJson().keys.toSet(), {
      PbFields.availableMinutesPerDay,
      PbFields.onboarded,
    });
  });
}
