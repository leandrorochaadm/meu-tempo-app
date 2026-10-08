import 'package:json_annotation/json_annotation.dart';

/// Active timer target type: leaf task or appointment.
///
/// The outside spelling (Firestore, route query param, native payload) is the
/// [apiValue] — never `.name` nor the index. `json_serializable` uses the same
/// field (`valueField`), so what is already stored does not change.
@JsonEnum(valueField: 'apiValue')
enum TimerTargetTypeEnum {
  task('task'),
  appointment('appointment');

  const TimerTargetTypeEnum(this.apiValue);

  final String apiValue;

  /// Converts the raw outside value. Unknown or missing → `null`: the reader
  /// decides the fallback (the target route goes back to the task list).
  static TimerTargetTypeEnum? fromApi(String? raw) {
    for (final type in values) {
      if (type.apiValue == raw) return type;
    }
    return null;
  }
}
