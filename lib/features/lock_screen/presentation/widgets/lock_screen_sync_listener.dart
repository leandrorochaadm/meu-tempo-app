import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/lock_screen_sync_bloc.dart';

/// Wires the [LockScreenSyncBloc] to the session and the app lifecycle, above
/// the router (also covers the login screen, where the timer bar does not
/// exist):
/// - signed in → starts mirroring the timer on the lock screen;
/// - signed out (left or opened signed out) → clears the lock screen;
/// - app back to the foreground → resubscribes and redraws the lock screen.
/// Draws nothing: returns [child] as is.
class LockScreenSyncListener extends StatefulWidget {
  const LockScreenSyncListener({super.key, required this.child});

  final Widget child;

  @override
  State<LockScreenSyncListener> createState() => _LockScreenSyncListenerState();
}

class _LockScreenSyncListenerState extends State<LockScreenSyncListener> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Fires only on the transition to "resumed"; opening the app is covered by
    // the auth state below.
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    // Session already resolved when mounted (e.g. hot restart): act right away.
    _dispatchFor(context.read<AuthBloc>().state);
  }

  void _onResume() =>
      context.read<LockScreenSyncBloc>().add(const LockScreenSyncAppResumed());

  void _dispatchFor(AuthState state) {
    final bloc = context.read<LockScreenSyncBloc>();
    switch (state) {
      case AuthAuthenticated():
        bloc.add(const LockScreenSyncStarted());
      case AuthUnauthenticated():
        bloc.add(const LockScreenSyncSignedOut());
      // Session still resolving, sign-in in progress or error (from signing in
      // or out): the session did not change, keep what is there.
      case AuthInitial() || AuthLoading() || AuthError():
        break;
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (_, state) => _dispatchFor(state),
      child: widget.child,
    );
  }
}
