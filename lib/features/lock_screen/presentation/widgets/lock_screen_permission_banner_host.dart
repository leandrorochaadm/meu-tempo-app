import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/app_notice_banner.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/lock_screen_permission_bloc.dart';

/// Wires the notifications-off banner to the signed-in screens (mounted in the
/// `AppShell`): starts watching the starts once the session is confirmed
/// (`AuthAuthenticated` — the shell mounts before the login resolves),
/// reevaluates when the app returns to the foreground and stops on sign-out or
/// unmount. Draws nothing: the banner comes out of [AppNoticeBanner]; returns
/// [child] as is.
class LockScreenPermissionBannerHost extends StatefulWidget {
  const LockScreenPermissionBannerHost({super.key, required this.child});

  final Widget child;

  @override
  State<LockScreenPermissionBannerHost> createState() =>
      _LockScreenPermissionBannerHostState();
}

class _LockScreenPermissionBannerHostState
    extends State<LockScreenPermissionBannerHost> {
  late final LockScreenPermissionBloc _bloc;
  late final AppLifecycleListener _lifecycle;
  ScaffoldMessengerState? _messenger;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<LockScreenPermissionBloc>();
    _lifecycle = AppLifecycleListener(
      onResume: () => _bloc.add(const LockScreenPermissionAppResumed()),
    );
    // Session already resolved when mounted (persistent login): act right away.
    _onAuthChanged(context.read<AuthBloc>().state);
  }

  /// Same pattern as the `LockScreenSyncListener`: the `redirect` does not
  /// redirect on `AuthInitial`/`AuthLoading`, so the shell exists before the
  /// `uid` — subscribing there would fail (`UnauthenticatedException`) and not
  /// come back.
  void _onAuthChanged(AuthState state) {
    switch (state) {
      case AuthAuthenticated():
        _bloc.add(const LockScreenPermissionStarted());
      case AuthUnauthenticated():
        _bloc.add(const LockScreenPermissionStopped());
      // Session resolving, sign-in in progress or error: keep as is.
      case AuthInitial() || AuthLoading() || AuthError():
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _bloc.add(const LockScreenPermissionStopped());
    // Removing the banner touches the ScaffoldMessenger (above this widget):
    // outside dispose, on the next frame — otherwise Flutter complains about
    // setState with the tree locked.
    final messenger = _messenger;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The whole app may be gone by then (messenger disposed too).
      if (messenger != null && messenger.mounted) {
        messenger.removeCurrentMaterialBanner();
      }
    });
    super.dispose();
  }

  void _render(BuildContext context, LockScreenPermissionState state) {
    switch (state) {
      case LockScreenPermissionBannerVisible():
        AppNoticeBanner.show(
          context,
          icon: Icons.notifications_off_rounded,
          message:
              'Ative os avisos para ver o cronômetro com o celular bloqueado',
          actionLabel: 'Abrir Ajustes',
          onAction: () =>
              _bloc.add(const LockScreenPermissionSettingsRequested()),
          onDismiss: () =>
              _bloc.add(const LockScreenPermissionBannerDismissed()),
        );
      case LockScreenPermissionBannerHidden():
        AppNoticeBanner.hide(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
          listener: (_, state) => _onAuthChanged(state),
        ),
        BlocListener<LockScreenPermissionBloc, LockScreenPermissionState>(
          listener: _render,
        ),
      ],
      child: widget.child,
    );
  }
}
