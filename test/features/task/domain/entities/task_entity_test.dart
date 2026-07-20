import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';

void main() {
  TaskEntity build({bool hasChildren = false}) => TaskEntity(
        id: '1',
        title: 'Tela de login',
        listId: 'inbox',
        createdAt: DateTime(2026, 7, 20),
        hasChildren: hasChildren,
      );

  group('TaskEntity.isLeaf', () {
    test('é folha quando não tem filhas', () {
      expect(build(hasChildren: false).isLeaf, isTrue);
    });

    test('não é folha quando tem filhas', () {
      expect(build(hasChildren: true).isLeaf, isFalse);
    });
  });

  test('ImportanceEnum tem os valores da fórmula de prioridade', () {
    expect(ImportanceEnum.max.value, 1);
    expect(ImportanceEnum.min.value, 4);
    // (5 - value): máxima pontua mais que mínima.
    expect(5 - ImportanceEnum.max.value, greaterThan(5 - ImportanceEnum.min.value));
  });

  test('igualdade por Equatable considera os campos', () {
    expect(build(), equals(build()));
  });
}
