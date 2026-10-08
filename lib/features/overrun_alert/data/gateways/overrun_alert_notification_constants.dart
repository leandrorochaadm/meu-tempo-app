/// Local notification settings (infrastructure, not rules). The small icon is
/// the Android resource kept by `res/raw/keep.xml`.
abstract final class OverrunAlertNotificationConstants {
  static const androidChannelId = 'overrun_alert';
  static const androidSmallIcon = 'ic_stat_timer';
  static const darwinThreadIdentifier = 'overrun_alert';

  /// IDs reserved to the series: [firstNotificationId] up to
  /// [firstNotificationId] + [scheduledAheadCount] − 1. Far from the 4101 of
  /// the timer service.
  static const firstNotificationId = 5100;

  /// Alerts scheduled ahead (48 h at the 1 h cadence). Below the iPhone limit
  /// of 64 pending notifications. The series is rebuilt when the plan changes,
  /// at each app start (new process) and at each lock screen button.
  static const scheduledAheadCount = 48;

  static const logName = 'OverrunAlert';
}
