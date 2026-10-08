import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/router/routes.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_target_type_enum.dart';

void main() {
  test('task target address', () {
    expect(
      Routes.timerTargetLocation(TimerTargetTypeEnum.task, 't1'),
      '/timer-target?type=task&id=t1',
    );
  });

  test('appointment target address', () {
    expect(
      Routes.timerTargetLocation(TimerTargetTypeEnum.appointment, 'a1'),
      '/timer-target?type=appointment&id=a1',
    );
  });

  test('round trip through the query params', () {
    final location = Routes.timerTargetLocation(TimerTargetTypeEnum.task, 't1');
    final q = Uri.parse(location).queryParameters;

    expect(
      TimerTargetTypeEnum.fromApi(q[TimerTargetQueryParams.type]),
      TimerTargetTypeEnum.task,
    );
    expect(q[TimerTargetQueryParams.id], 't1');
  });
}
