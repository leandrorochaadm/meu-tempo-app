import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';

void main() {
  test('apiValue of each importance', () {
    expect(ImportanceEnum.max.apiValue, 'max');
    expect(ImportanceEnum.high.apiValue, 'high');
    expect(ImportanceEnum.low.apiValue, 'low');
    expect(ImportanceEnum.min.apiValue, 'min');
  });

  test('fromApi reads each spelling back', () {
    for (final importance in ImportanceEnum.values) {
      expect(ImportanceEnum.fromApi(importance.apiValue), importance);
    }
  });

  test('fromApi unknown or missing returns null', () {
    expect(ImportanceEnum.fromApi(null), isNull);
    expect(ImportanceEnum.fromApi(''), isNull);
    expect(ImportanceEnum.fromApi('Max'), isNull);
    expect(ImportanceEnum.fromApi('urgent'), isNull);
  });

  test('value keeps 1 to 4', () {
    expect(ImportanceEnum.values.map((e) => e.value), [1, 2, 3, 4]);
  });
}
