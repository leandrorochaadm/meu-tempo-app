part of 'lock_screen_permission_bloc.dart';

sealed class LockScreenPermissionState extends Equatable {
  const LockScreenPermissionState();

  @override
  List<Object?> get props => const [];
}

/// No banner.
class LockScreenPermissionBannerHidden extends LockScreenPermissionState {
  const LockScreenPermissionBannerHidden();
}

/// "Ative os avisos..." banner in view (a start happened with notifications
/// off).
class LockScreenPermissionBannerVisible extends LockScreenPermissionState {
  const LockScreenPermissionBannerVisible();
}
