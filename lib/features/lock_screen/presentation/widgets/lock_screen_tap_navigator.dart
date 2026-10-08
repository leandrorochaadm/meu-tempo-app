import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/lock_screen_tap_bloc.dart';

/// Opens the task or appointment tapped on the lock screen timer (route
/// `Routes.timerTarget`). Mounted in the `AppShell`, which exists before the
/// login resolves (the `redirect` waits on `AuthInitial`): the tap stays
/// pending in the [LockScreenTapBloc] and only opens with `AuthAuthenticated` —
/// on the first frame (app opened by the tap, session already resolved), when
/// the tap arrives or when the login finishes.
class LockScreenTapNavigator extends StatefulWidget {
  const LockScreenTapNavigator({super.key, required this.child});

  final Widget child;

  @override
  State<LockScreenTapNavigator> createState() => _LockScreenTapNavigatorState();
}

class _LockScreenTapNavigatorState extends State<LockScreenTapNavigator> {
  /// Last pending tap already opened: `Handled` is asynchronous and the first
  /// frame, the tap and the login may ask for the same pending tap more than
  /// once.
  LockScreenTapPending? _opened;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openPending();
    });
  }

  void _openPending() {
    final tapState = context.read<LockScreenTapBloc>().state;
    if (tapState is! LockScreenTapPending || identical(tapState, _opened)) {
      return;
    }
    if (context.read<AuthBloc>().state is! AuthAuthenticated) return;
    _opened = tapState;
    final tap = tapState.tap;
    context.read<LockScreenTapBloc>().add(LockScreenTapHandled(tap));
    context.push(Routes.timerTargetLocation(tap.targetType, tap.targetId));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LockScreenTapBloc, LockScreenTapState>(
          listenWhen: (_, curr) => curr is LockScreenTapPending,
          listener: (_, _) => _openPending(),
        ),
        // Tap that arrived while the login was resolving: opens on sign-in.
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              prev.runtimeType != curr.runtimeType && curr is AuthAuthenticated,
          listener: (_, _) => _openPending(),
        ),
      ],
      child: widget.child,
    );
  }
}
