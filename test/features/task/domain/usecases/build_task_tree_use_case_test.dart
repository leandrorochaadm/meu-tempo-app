import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_prioritized_leaves_use_case.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/usecases/build_task_tree_use_case.dart';

void main() {
  final today = DateTime(2026, 7, 20);
  const useCase = BuildTaskTreeUseCase(GetPrioritizedLeavesUseCase());

  TaskEntity t(
    String id, {
    String? parentId,
    DateTime? dueDate,
    bool hasChildren = false,
  }) =>
      TaskEntity(
        id: id,
        title: id,
        listId: 'inbox',
        createdAt: today,
        parentId: parentId,
        dueDate: dueDate,
        estimatedMinutes: 30,
        hasChildren: hasChildren,
      );

  test('monta mãe → filha → neta com níveis corretos', () {
    final roots = useCase([
      t('mae'),
      t('filha', parentId: 'mae'),
      t('neta', parentId: 'filha'),
    ]);

    expect(roots.length, 1);
    final mae = roots.single;
    expect(mae.level, 0);
    expect(mae.children.single.level, 1);
    expect(mae.children.single.children.single.level, 2);
    expect(mae.children.single.children.single.task.id, 'neta');
  });

  test('múltiplas raízes e folhas soltas', () {
    final roots = useCase([t('a'), t('b')]);
    expect(roots.map((n) => n.task.id), containsAll(['a', 'b']));
    expect(roots.every((n) => n.isLeaf), isTrue);
  });

  test('marca folha atrasada quando recebe `today`', () {
    final roots = useCase(
      [
        t('atrasada', dueDate: DateTime(2026, 7, 19)),
        t('no prazo', dueDate: DateTime(2026, 7, 25)),
      ],
      today,
    );
    final byId = {for (final n in roots) n.task.id: n};
    expect(byId['atrasada']!.isOverdue, isTrue);
    expect(byId['no prazo']!.isOverdue, isFalse);
  });

  test('sem `today` nenhuma folha é marcada como atrasada', () {
    final roots = useCase([t('atrasada', dueDate: DateTime(2026, 7, 19))]);
    expect(roots.single.isOverdue, isFalse);
  });

  group('rank — posição na fila de prioridade', () {
    test('numera as folhas na ordem da fila, mesmo aninhadas', () {
      // Mesma estimativa (30 min) e importância; o prazo decide a ordem.
      final roots = useCase(
        [
          t('mae', hasChildren: true),
          t('filha',
              parentId: 'mae',
              dueDate: DateTime(2026, 7, 30),
              hasChildren: true),
          t('neta', parentId: 'filha', dueDate: DateTime(2026, 7, 20)),
          t('solta', dueDate: DateTime(2026, 7, 22)),
        ],
        today,
      );

      final byId = {for (final n in roots) n.task.id: n};
      final mae = byId['mae']!;
      final filha = mae.children.single;
      final neta = filha.children.single;

      expect(neta.rank, 1); // vence hoje
      expect(byId['solta']!.rank, 2); // em 2 dias
      expect(filha.rank, isNull); // deixou de ser folha (tem a neta)
    });

    test('mãe e avó não recebem posição', () {
      final roots = useCase(
        [
          t('mae', hasChildren: true),
          t('filha', parentId: 'mae', dueDate: today),
        ],
        today,
      );

      expect(roots.single.rank, isNull);
      expect(roots.single.children.single.rank, 1);
    });

    test('folha concluída não recebe posição', () {
      final roots = useCase(
        [
          TaskEntity(
            id: 'feita',
            title: 'feita',
            listId: 'inbox',
            createdAt: today,
            dueDate: today,
            estimatedMinutes: 30,
            isDone: true,
          ),
          t('pendente', dueDate: today),
        ],
        today,
      );

      final byId = {for (final n in roots) n.task.id: n};
      expect(byId['feita']!.rank, isNull);
      expect(byId['pendente']!.rank, 1);
    });

    test('sem `today` nenhuma folha recebe posição', () {
      final roots = useCase([t('a', dueDate: today)]);
      expect(roots.single.rank, isNull);
    });
  });

  group('coleção filtrada (filha ausente da projeção)', () {
    test('mãe sem filhas visíveis não é tratada como folha', () {
      // Cenário do filtro por lista: a mãe está na lista selecionada, a filha
      // (de outra lista) foi removida da coleção antes de montar a árvore.
      final roots = useCase([t('mae', hasChildren: true)], today);

      final mae = roots.single;
      expect(mae.children, isEmpty); // a filha não veio na projeção
      expect(mae.isLeaf, isFalse); // mas ela não é folha
    });

    test('mãe sem filhas visíveis fica fora da fila de prioridade', () {
      final roots = useCase(
        [t('mae', hasChildren: true, dueDate: today)],
        today,
      );

      expect(roots.single.rank, isNull);
    });
  });
}
