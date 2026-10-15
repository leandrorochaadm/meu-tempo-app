import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';

void main() {
  TaskEntity build({
    bool hasChildren = false,
    bool isDone = false,
    String? recurringTaskId,
  }) => TaskEntity(
    id: '1',
    title: 'Tela de login',
    listId: 'inbox',
    createdAt: DateTime(2026, 7, 20),
    hasChildren: hasChildren,
    isDone: isDone,
    recurringTaskId: recurringTaskId,
  );

  group('TaskEntity.isLeaf', () {
    test('é folha quando não tem filhas', () {
      expect(build(hasChildren: false).isLeaf, isTrue);
    });

    test('não é folha quando tem filhas', () {
      expect(build(hasChildren: true).isLeaf, isFalse);
    });
  });

  group('TaskEntity.isPendingInstanceOf', () {
    test(
      'isPendingInstanceOf should be true for pending instance of the template',
      () {
        expect(build(recurringTaskId: 'r1').isPendingInstanceOf('r1'), isTrue);
      },
    );

    test('isPendingInstanceOf should be false when done or other template', () {
      expect(
        build(recurringTaskId: 'r1', isDone: true).isPendingInstanceOf('r1'),
        isFalse,
      );
      expect(build(recurringTaskId: 'r2').isPendingInstanceOf('r1'), isFalse);
      expect(build().isPendingInstanceOf('r1'), isFalse);
    });

    test('entities differing only by recurringTaskId are not equal', () {
      expect(build(recurringTaskId: 'r1'), isNot(equals(build())));
    });
  });

  test('ImportanceEnum tem os valores da fórmula de prioridade', () {
    expect(ImportanceEnum.max.value, 1);
    expect(ImportanceEnum.min.value, 4);
    // (5 - value): máxima pontua mais que mínima.
    expect(
      5 - ImportanceEnum.max.value,
      greaterThan(5 - ImportanceEnum.min.value),
    );
  });

  test('igualdade por Equatable considera os campos', () {
    expect(build(), equals(build()));
  });
}
