import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/utils/record_id_generator.dart';

void main() {
  test('next matches the PocketBase id format', () {
    expect(RecordIdGenerator.next(), matches(RegExp(r'^[a-z0-9]{15}$')));
  });

  test('1000 ids are unique', () {
    final ids = List.generate(1000, (_) => RecordIdGenerator.next());
    expect(ids.toSet().length, 1000);
  });
}
