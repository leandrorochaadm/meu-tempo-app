import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

void main() {
  test('apiValue of each type', () {
    expect(TimerTargetTypeEnum.task.apiValue, 'task');
    expect(TimerTargetTypeEnum.appointment.apiValue, 'appointment');
  });

  test('fromApi reads each spelling back', () {
    for (final type in TimerTargetTypeEnum.values) {
      expect(TimerTargetTypeEnum.fromApi(type.apiValue), type);
    }
  });

  test('fromApi unknown or missing returns null', () {
    expect(TimerTargetTypeEnum.fromApi('Task'), isNull);
    expect(TimerTargetTypeEnum.fromApi(''), isNull);
    expect(TimerTargetTypeEnum.fromApi(null), isNull);
  });
}
