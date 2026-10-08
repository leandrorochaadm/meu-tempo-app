import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/app_notice_banner.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/overrun_alert_bloc.dart';

/// Wires the overrun alert banner to the signed-in screens (mounted in the
/// `AppShell`): starts once the session is confirmed (`AuthAuthenticated`),
/// stops on sign-out. Draws nothing: the banner comes out of
/// [AppNoticeBanner]; returns [child] as is.
class OverrunAlertHost extends StatefulWidget {
  const OverrunAlertHost({super.key, required this.child});

  final Widget child;

  @override
  State<OverrunAlertHost> createState() => _OverrunAlertHostState();
}

class _OverrunAlertHostState extends State<OverrunAlertHost> {
  late final OverrunAlertBloc _bloc;
  ScaffoldMessengerState? _messenger;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<OverrunAlertBloc>();
    // Session already resolved when mounted (persistent login): act right away.
    _onAuthChanged(context.read<AuthBloc>().state);
  }

  /// The shell mounts before the login resolves, so only act on the confirmed
  /// states.
  void _onAuthChanged(AuthState state) {
    switch (state) {
      case AuthAuthenticated():
        _bloc.add(const OverrunAlertStarted());
      case AuthUnauthenticated():
        _bloc.add(const OverrunAlertSignedOut());
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
    // Does not sign out: the series must survive the shell (sign-out arrives
    // through the AuthBloc). Only takes the banner off the screen, on the next
    // frame, because the ScaffoldMessenger is above this widget.
    final messenger = _messenger;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messenger != null && messenger.mounted) {
        messenger.removeCurrentMaterialBanner();
      }
    });
    super.dispose();
  }

  void _render(BuildContext context, OverrunAlertState state) {
    switch (state) {
      case OverrunAlertVisible(:final alert):
        AppNoticeBanner.show(
          context,
          icon: Icons.hourglass_bottom_rounded,
          message: '“${alert.title}” passou do tempo estimado.',
          actionLabel: 'Pausar',
          onAction: () => _bloc.add(const OverrunAlertPauseRequested()),
          onDismiss: () => _bloc.add(const OverrunAlertDismissed()),
        );
      case OverrunAlertPauseFailed(:final message):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      case OverrunAlertHidden():
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
        BlocListener<OverrunAlertBloc, OverrunAlertState>(
          // Retry after a failed pause: the banner is already on screen.
          listenWhen: (prev, curr) =>
              !(prev is OverrunAlertPauseFailed &&
                  curr is OverrunAlertVisible &&
                  prev.alert == curr.alert),
          listener: _render,
        ),
      ],
      child: widget.child,
    );
  }
}
