import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/usecases/build_task_tree_use_case.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_task_edit_context_use_case.dart';

void main() {
  final today = DateTime(2026, 7, 20);
  const useCase = GetTaskEditContextUseCase(BuildTaskTreeUseCase());

  TaskEntity t(String id, {String? parentId}) => TaskEntity(
        id: id,
        title: id,
        listId: 'inbox',
        createdAt: today,
        parentId: parentId,
      );

  // Árvore: mae → filha → neta, e uma raiz solta "outra".
  final tasks = [
    t('mae'),
    t('filha', parentId: 'mae'),
    t('neta', parentId: 'filha'),
    t('outra'),
  ];

  test('retorna null quando a tarefa não existe', () {
    expect(useCase('inexistente', tasks), isNull);
  });

  test('exclui a própria e seus descendentes dos candidatos a mãe', () {
    final ctx = useCase('mae', tasks)!;
    final ids = ctx.parentCandidates.map((c) => c.id);

    expect(ctx.task.id, 'mae');
    // "mae", "filha" e "neta" ficam de fora (própria + descendentes).
    expect(ids, isNot(contains('mae')));
    expect(ids, isNot(contains('filha')));
    expect(ids, isNot(contains('neta')));
    // "outra" é raiz válida.
    expect(ids, contains('outra'));
  });

  test('neta (nível máximo) nunca é candidata a mãe', () {
    final ctx = useCase('outra', tasks)!;
    final ids = ctx.parentCandidates.map((c) => c.id);
    expect(ids, isNot(contains('neta')));
    // mãe e filha podem receber filhas.
    expect(ids, containsAll(['mae', 'filha']));
  });

  test('carrega o nível e os títulos dos ancestrais de cada candidato', () {
    final ctx = useCase('outra', tasks)!;
    final filha = ctx.parentCandidates.firstWhere((c) => c.id == 'filha');
    expect(filha.level, 1);
    expect(filha.ancestorTitles, ['mae']);
  });

  test('breadcrumb da mãe atual reflete a cadeia de ancestrais', () {
    final ctx = useCase('neta', tasks)!;
    expect(ctx.currentParentLabel, 'mae › filha');
  });

  test('tarefa raiz tem breadcrumb vazio', () {
    final ctx = useCase('mae', tasks)!;
    expect(ctx.currentParentLabel, '');
  });
}
