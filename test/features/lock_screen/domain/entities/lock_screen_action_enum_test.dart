import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_action_enum.dart';

void main() {
  test('apiValue de cada ação', () {
    expect(LockScreenActionEnum.pause.apiValue, 'pause');
    expect(LockScreenActionEnum.resume.apiValue, 'resume');
    expect(LockScreenActionEnum.stopConfirmed.apiValue, 'stop_confirmed');
  });

  test('fromApi lê cada grafia', () {
    for (final action in LockScreenActionEnum.values) {
      expect(LockScreenActionEnum.fromApi(action.apiValue), action);
    }
  });

  test('fromApi desconhecido ou ausente devolve null', () {
    expect(LockScreenActionEnum.fromApi('stop'), isNull);
    expect(LockScreenActionEnum.fromApi(''), isNull);
    expect(LockScreenActionEnum.fromApi(null), isNull);
  });
}
