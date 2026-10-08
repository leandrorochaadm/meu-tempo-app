import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/lock_screen/data/background/lock_screen_action_reply_enum.dart';
import 'package:meu_tempo/features/lock_screen/data/background/lock_screen_channel_method_enum.dart';

void main() {
  group('LockScreenChannelMethodEnum', () {
    test('apiValue de cada método', () {
      expect(
        LockScreenChannelMethodEnum.backgroundReady.apiValue,
        'backgroundReady',
      );
      expect(
        LockScreenChannelMethodEnum.backgroundFailed.apiValue,
        'backgroundFailed',
      );
      expect(LockScreenChannelMethodEnum.handleAction.apiValue, 'handleAction');
    });

    test('fromApi faz a volta e devolve null para desconhecido', () {
      for (final method in LockScreenChannelMethodEnum.values) {
        expect(LockScreenChannelMethodEnum.fromApi(method.apiValue), method);
      }
      expect(LockScreenChannelMethodEnum.fromApi('other'), isNull);
      expect(LockScreenChannelMethodEnum.fromApi(null), isNull);
    });
  });

  test('LockScreenActionReplyEnum: apiValue de cada resposta', () {
    expect(LockScreenActionReplyEnum.show.apiValue, 'show');
    expect(LockScreenActionReplyEnum.clear.apiValue, 'clear');
    expect(LockScreenActionReplyEnum.unchanged.apiValue, 'unchanged');
  });
}
