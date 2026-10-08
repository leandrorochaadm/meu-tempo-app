import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/lock_screen/domain/entities/lock_screen_permission_status_enum.dart';

void main() {
  test('fromApi lê cada grafia', () {
    for (final status in LockScreenPermissionStatusEnum.values) {
      expect(LockScreenPermissionStatusEnum.fromApi(status.apiValue), status);
    }
  });

  test('fromApi desconhecido ou ausente devolve unsupported', () {
    expect(
      LockScreenPermissionStatusEnum.fromApi('maybe'),
      LockScreenPermissionStatusEnum.unsupported,
    );
    expect(
      LockScreenPermissionStatusEnum.fromApi(null),
      LockScreenPermissionStatusEnum.unsupported,
    );
  });

  test('só denied bloqueia a tela bloqueada', () {
    expect(LockScreenPermissionStatusEnum.denied.blocksLockScreen, isTrue);
    expect(LockScreenPermissionStatusEnum.granted.blocksLockScreen, isFalse);
    expect(
      LockScreenPermissionStatusEnum.unsupported.blocksLockScreen,
      isFalse,
    );
  });
}
