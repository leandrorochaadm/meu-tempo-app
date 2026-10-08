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

  test('fromApi lê not_requested', () {
    expect(
      LockScreenPermissionStatusEnum.fromApi('not_requested'),
      LockScreenPermissionStatusEnum.notRequested,
    );
  });

  test('só notRequested pede a permissão', () {
    for (final status in LockScreenPermissionStatusEnum.values) {
      expect(
        status.shouldRequest,
        status == LockScreenPermissionStatusEnum.notRequested,
      );
    }
  });

  test('só denied bloqueia a tela bloqueada', () {
    expect(LockScreenPermissionStatusEnum.denied.blocksLockScreen, isTrue);
    expect(
      LockScreenPermissionStatusEnum.notRequested.blocksLockScreen,
      isFalse,
    );
    expect(LockScreenPermissionStatusEnum.granted.blocksLockScreen, isFalse);
    expect(
      LockScreenPermissionStatusEnum.unsupported.blocksLockScreen,
      isFalse,
    );
  });
}
