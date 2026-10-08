/// What the native side must do after a lock screen action. Dart only writes
/// these values; the native side reads them.
enum LockScreenActionReplyEnum {
  /// Redraw with the `timer` that comes along.
  show('show'),

  /// Remove from the lock screen and the notification shade.
  clear('clear'),

  /// Go back to the last drawing (action ignored or failed).
  unchanged('unchanged');

  const LockScreenActionReplyEnum(this.apiValue);

  final String apiValue;
}
