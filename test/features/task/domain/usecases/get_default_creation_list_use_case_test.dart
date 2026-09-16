import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_default_creation_list_use_case.dart';

void main() {
  const useCase = GetDefaultCreationListUseCase();
  const disponiveis = ['inbox', 'trabalho', 'estudos'];

  final antiga = TaskEntity(
    id: 'a',
    title: 'Antiga',
    listId: 'estudos',
    createdAt: DateTime(2026, 9, 10),
  );
  final recente = TaskEntity(
    id: 'b',
    title: 'Recente',
    listId: 'trabalho',
    createdAt: DateTime(2026, 9, 14),
  );

  test('a escolha explícita da barra vence tudo', () {
    final destino = useCase(
      [antiga, recente],
      availableListIds: disponiveis,
      chosenListId: 'estudos',
      filterListId: 'trabalho',
      inboxListId: 'inbox',
    );
    expect(destino, 'estudos');
  });

  test('sem escolha explícita, vale a lista do filtro ativo', () {
    final destino = useCase(
      [antiga, recente],
      availableListIds: disponiveis,
      filterListId: 'trabalho',
      inboxListId: 'inbox',
    );
    expect(destino, 'trabalho');
  });

  test('sem escolha e sem filtro, vale a lista da tarefa mais recente', () {
    final destino = useCase(
      [antiga, recente],
      availableListIds: disponiveis,
      inboxListId: 'inbox',
    );
    expect(destino, 'trabalho');
  });

  test('sem tarefas, cai na Entrada', () {
    final destino = useCase(
      const [],
      availableListIds: disponiveis,
      inboxListId: 'inbox',
    );
    expect(destino, 'inbox');
  });

  test('ids de listas que não existem mais são descartados', () {
    final destino = useCase(
      [antiga],
      availableListIds: const ['inbox'],
      chosenListId: 'apagada',
      filterListId: 'apagada',
      inboxListId: 'inbox',
    );
    expect(destino, 'inbox');
  });

  test('lista de listas ainda vazia (stream não chegou) cai na Entrada', () {
    final destino = useCase(
      [recente],
      availableListIds: const [],
      chosenListId: 'trabalho',
      inboxListId: 'inbox',
    );
    expect(destino, 'inbox');
  });
}
