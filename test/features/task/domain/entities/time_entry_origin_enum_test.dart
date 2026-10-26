import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/time_entry_origin_enum.dart';

void main() {
  test('apiValue of each origin', () {
    expect(TimeEntryOriginEnum.timer.apiValue, 'timer');
    expect(TimeEntryOriginEnum.manual.apiValue, 'manual');
  });

  test('fromApi reads each spelling back', () {
    for (final origin in TimeEntryOriginEnum.values) {
      expect(TimeEntryOriginEnum.fromApi(origin.apiValue), origin);
    }
  });

  test('fromApi unknown or missing returns null', () {
    expect(TimeEntryOriginEnum.fromApi(null), isNull);
    expect(TimeEntryOriginEnum.fromApi(''), isNull);
    expect(TimeEntryOriginEnum.fromApi('Manual'), isNull);
  });
}
