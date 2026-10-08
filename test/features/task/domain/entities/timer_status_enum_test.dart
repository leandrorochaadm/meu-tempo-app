import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/timer_status_enum.dart';

void main() {
  group('TimerStatusEnum', () {
    test('apiValue de cada status', () {
      expect(TimerStatusEnum.running.apiValue, 'running');
      expect(TimerStatusEnum.paused.apiValue, 'paused');
    });

    test('fromApi lê cada grafia', () {
      expect(TimerStatusEnum.fromApi('running'), TimerStatusEnum.running);
      expect(TimerStatusEnum.fromApi('paused'), TimerStatusEnum.paused);
    });

    test('fromApi sem valor (doc antigo) devolve running', () {
      expect(TimerStatusEnum.fromApi(null), TimerStatusEnum.running);
    });

    test('fromApi com valor desconhecido devolve running', () {
      expect(TimerStatusEnum.fromApi('stopped'), TimerStatusEnum.running);
    });
  });
}
