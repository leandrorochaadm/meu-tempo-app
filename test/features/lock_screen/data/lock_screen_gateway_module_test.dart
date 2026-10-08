import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/lock_screen/data/gateways/native_lock_screen_timer_gateway.dart';
import 'package:meu_tempo/features/lock_screen/data/gateways/noop_lock_screen_timer_gateway.dart';
import 'package:meu_tempo/features/lock_screen/data/lock_screen_gateway_module.dart';

class _Module extends LockScreenGatewayModule {}

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('Android usa o gateway nativo', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(
      _Module().lockScreenTimerGateway,
      isA<NativeLockScreenTimerGateway>(),
    );
  });

  test('iPhone usa o gateway nativo', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    expect(
      _Module().lockScreenTimerGateway,
      isA<NativeLockScreenTimerGateway>(),
    );
  });

  test('outras plataformas usam o vazio', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    expect(_Module().lockScreenTimerGateway, isA<NoopLockScreenTimerGateway>());
  });
}
