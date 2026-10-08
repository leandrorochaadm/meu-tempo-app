import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import 'get_lock_screen_permission_status_use_case.dart';
import 'watch_lock_screen_timer_starts_use_case.dart';

/// Rule "phone notifications off → on start, the app shows a banner": emits
/// `Right(unit)` on every start ([WatchLockScreenTimerStartsUseCase]) in which
/// the notification permission blocks the lock screen timer
/// (`LockScreenPermissionStatusEnum.blocksLockScreen` — never in the browser,
/// which is `unsupported`).
///
/// - A start with notifications on (or in the browser) does not emit.
/// - Failure reading the permission → `Left`: no warning; the subscriber only
///   logs it.
/// - The permission is read on every start (the user may change it in the
///   settings at any time), one start at a time, in order.
@lazySingleton
class WatchLockScreenPermissionWarningsUseCase
    implements StreamUseCase<Either<Failure, Unit>, NoParams> {
  const WatchLockScreenPermissionWarningsUseCase(
    this._watchTimerStarts,
    this._getPermissionStatus,
  );

  final WatchLockScreenTimerStartsUseCase _watchTimerStarts;
  final GetLockScreenPermissionStatusUseCase _getPermissionStatus;

  @override
  Stream<Either<Failure, Unit>> call(NoParams params) =>
      // `asyncExpand` handles one start at a time, in order; and (unlike
      // `async*`) cancelling goes straight to the source.
      _watchTimerStarts(params).asyncExpand(
        (_) => Stream.fromFuture(_getPermissionStatus(params)).expand((result) {
          final failure = result.getLeft().toNullable();
          if (failure != null) return [Left<Failure, Unit>(failure)];
          final blocks =
              result.getRight().toNullable()?.blocksLockScreen ?? false;
          return blocks
              ? [const Right<Failure, Unit>(unit)]
              : const <Either<Failure, Unit>>[];
        }),
      );
}
