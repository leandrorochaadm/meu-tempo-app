import 'package:injectable/injectable.dart';

import 'pocketbase_session.dart';

typedef RealtimeUnsubscribe = Future<void> Function();

/// Smallest boundary with the SDK realtime, so [RecordWatcher] can be tested
/// without network.
abstract interface class RealtimeSubscriber {
  Future<RealtimeUnsubscribe> subscribe(String topic, void Function() onEvent);
}

abstract final class RealtimeTopics {
  /// Event the SDK delivers on every (re)connection of the SSE channel.
  static const String connect = 'PB_CONNECT';

  static String allRecords(String collection) => '$collection/*';
}

@LazySingleton(as: RealtimeSubscriber)
class PocketBaseRealtimeSubscriber implements RealtimeSubscriber {
  PocketBaseRealtimeSubscriber(this._session);

  final PocketBaseSession _session;

  /// The event content does not matter: the watcher always reloads. A
  /// `ClientException` leaves untranslated.
  @override
  Future<RealtimeUnsubscribe> subscribe(
    String topic,
    void Function() onEvent,
  ) => _session.client.realtime.subscribe(topic, (_) => onEvent());
}
