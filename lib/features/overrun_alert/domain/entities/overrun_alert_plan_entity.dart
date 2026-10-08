import 'package:equatable/equatable.dart';

/// Series of overrun alerts of one running timer: the first alert plus the
/// repeat cadence. Immutable.
class OverrunAlertPlanEntity extends Equatable {
  const OverrunAlertPlanEntity({
    required this.targetId,
    required this.title,
    required this.firstAlertAt,
    required this.repeatInterval,
  });

  final String targetId;
  final String title;
  final DateTime firstAlertAt;
  final Duration repeatInterval;

  /// First alert of the series at [now] or later (>=). Exactly at the alert
  /// time counts as "now": the alert goes out right away.
  DateTime nextAlertAt(DateTime now) {
    if (!now.isAfter(firstAlertAt)) return firstAlertAt;
    final step = repeatInterval.inMicroseconds;
    final elapsed = now.difference(firstAlertAt).inMicroseconds;
    return firstAlertAt.add(
      Duration(microseconds: ((elapsed + step - 1) ~/ step) * step),
    );
  }

  /// First alert of the series strictly after [moment] (>). Used after an
  /// alert fires: missed alerts (suspended tab, closed app) are not replayed
  /// in a burst, only the next one comes.
  DateTime alertAfter(DateTime moment) {
    if (moment.isBefore(firstAlertAt)) return firstAlertAt;
    final step = repeatInterval.inMicroseconds;
    final elapsed = moment.difference(firstAlertAt).inMicroseconds;
    return firstAlertAt.add(
      Duration(microseconds: (elapsed ~/ step + 1) * step),
    );
  }

  @override
  List<Object?> get props => [targetId, title, firstAlertAt, repeatInterval];
}
