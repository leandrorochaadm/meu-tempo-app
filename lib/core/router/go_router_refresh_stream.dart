import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapta um `Stream` para o `refreshListenable` do go_router — reavalia o
/// `redirect` sempre que o stream (ex.: estado de auth) emite.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
