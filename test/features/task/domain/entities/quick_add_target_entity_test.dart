import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/quick_add_target_entity.dart';

void main() {
  QuickAddTargetEntity target(int level) => QuickAddTargetEntity(
        taskId: 't1',
        title: 'Lançar app',
        listId: 'inbox',
        level: level,
      );

  test('mãe (nível 0) aceita filha', () {
    expect(target(0).acceptsChild, isTrue);
  });

  test('filha (nível 1) aceita neta', () {
    expect(target(1).acceptsChild, isTrue);
  });

  test('neta (nível 2) não aceita filha — é o último nível', () {
    expect(target(2).acceptsChild, isFalse);
  });

  test('compara por valor (Equatable)', () {
    expect(target(0), target(0));
    expect(target(0), isNot(target(1)));
  });
}
