import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/task/domain/entities/importance_enum.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/usecases/get_prioritized_leaves_use_case.dart';

void main() {
  const useCase = GetPrioritizedLeavesUseCase();
  final today = DateTime(2026, 7, 20);

  TaskEntity leaf(
    String id, {
    required int minutes,
    required ImportanceEnum importance,
    required int dueInDays,
    String? parentId,
    bool done = false,
    bool hasChildren = false,
  }) =>
      TaskEntity(
        id: id,
        title: id,
        listId: 'inbox',
        createdAt: today,
        parentId: parentId,
        estimatedMinutes: minutes,
        importance: importance,
        dueDate: today.add(Duration(days: dueInDays)),
        isDone: done,
        hasChildren: hasChildren,
      );

  test('exemplo do requisito: 2h/imp1/hoje acima de 2h/imp1/+4d', () {
    final result = useCase([
      leaf('hoje',
          minutes: 120, importance: ImportanceEnum.max, dueInDays: 0),
      leaf('depois',
          minutes: 120, importance: ImportanceEnum.max, dueInDays: 4),
    ], today);

    expect(result.first.task.id, 'hoje');
    // 120 min = faixa longa (4): 4 × (5−1) × 6 = 96 ; 4 × (5−1) × 4 = 64
    expect(result[0].priority, 96);
    expect(result[1].priority, 64);
  });

  test('urgência e importância ganham de uma tarefa longa e irrelevante', () {
    final result = useCase([
      leaf('longa',
          minutes: 480, importance: ImportanceEnum.min, dueInDays: 30),
      leaf('curta_urgente',
          minutes: 15, importance: ImportanceEnum.max, dueInDays: 0),
    ], today);

    expect(result.map((l) => l.task.id), ['curta_urgente', 'longa']);
  });

  test('rank numera a posição final, começando em 1', () {
    final result = useCase([
      // Fora de ordem na entrada: o rank vem da ordenação, não da entrada.
      leaf('depois',
          minutes: 120, importance: ImportanceEnum.max, dueInDays: 4),
      leaf('hoje', minutes: 120, importance: ImportanceEnum.max, dueInDays: 0),
      leaf('longe',
          minutes: 120, importance: ImportanceEnum.max, dueInDays: 30),
    ], today);

    expect(result.map((l) => l.task.id), ['hoje', 'depois', 'longe']);
    expect(result.map((l) => l.rank), [1, 2, 3]);
  });

  test('exclui folhas concluídas e não-folhas', () {
    final result = useCase([
      leaf('done',
          minutes: 60, importance: ImportanceEnum.max, dueInDays: 0, done: true),
      leaf('mae',
          minutes: 60,
          importance: ImportanceEnum.max,
          dueInDays: 0,
          hasChildren: true),
      leaf('ok', minutes: 60, importance: ImportanceEnum.max, dueInDays: 0),
    ], today);

    expect(result.map((l) => l.task.id), ['ok']);
  });

  test('marca isOverdue nas folhas com prazo antes de hoje', () {
    final result = useCase([
      leaf('atrasada',
          minutes: 60, importance: ImportanceEnum.max, dueInDays: -1),
      leaf('hoje', minutes: 60, importance: ImportanceEnum.max, dueInDays: 0),
      leaf('futura', minutes: 60, importance: ImportanceEnum.max, dueInDays: 3),
    ], today);

    final byId = {for (final l in result) l.task.id: l};
    expect(byId['atrasada']!.isOverdue, isTrue);
    expect(byId['hoje']!.isOverdue, isFalse);
    expect(byId['futura']!.isOverdue, isFalse);
  });

  group('desempate determinístico', () {
    test('mesmo score: prazo mais próximo primeiro', () {
      // 20 e 30 min caem na mesma faixa (curta), então o score empata.
      final result = useCase([
        leaf('depois',
            minutes: 20, importance: ImportanceEnum.max, dueInDays: 2),
        leaf('antes',
            minutes: 30, importance: ImportanceEnum.max, dueInDays: 1),
      ], today);

      expect(result.map((l) => l.task.id), ['antes', 'depois']);
    });

    test('a hora dentro do dia do prazo não decide a ordem', () {
      // A criação rápida grava `dueDate` com a hora de `DateTime.now()`; o
      // desempate é por dia, então quem decide aqui é a estimativa maior.
      TaskEntity comHora(String id, {required int minutes, required int hour}) =>
          TaskEntity(
            id: id,
            title: id,
            listId: 'inbox',
            createdAt: today,
            estimatedMinutes: minutes,
            importance: ImportanceEnum.max,
            dueDate: today.add(Duration(days: 1, hours: hour)),
          );

      final result = useCase([
        comHora('cedo_e_menor', minutes: 20, hour: 8),
        comHora('tarde_e_maior', minutes: 30, hour: 20),
      ], today);

      expect(result.map((l) => l.task.id), ['tarde_e_maior', 'cedo_e_menor']);
    });

    test('mesmo prazo: a estimativa maior dentro da faixa vem primeiro', () {
      final result = useCase([
        leaf('menor',
            minutes: 20, importance: ImportanceEnum.max, dueInDays: 1),
        leaf('maior',
            minutes: 30, importance: ImportanceEnum.max, dueInDays: 1),
      ], today);

      expect(result.map((l) => l.task.id), ['maior', 'menor']);
    });

    test('folha sem prazo vai para o fim do empate', () {
      final semPrazo = TaskEntity(
        id: 'sem_prazo',
        title: 'sem_prazo',
        listId: 'inbox',
        createdAt: today,
        estimatedMinutes: 60,
        importance: ImportanceEnum.min,
      );
      final comPrazo = leaf('com_prazo',
          minutes: 60, importance: ImportanceEnum.min, dueInDays: 30);

      expect(
        useCase([semPrazo, comPrazo], today).map((l) => l.task.id),
        ['com_prazo', 'sem_prazo'],
      );
    });

    test('tudo igual: mais antiga primeiro e o id fecha a ordem', () {
      TaskEntity gemea(String id, {required DateTime createdAt}) => TaskEntity(
            id: id,
            title: id,
            listId: 'inbox',
            createdAt: createdAt,
            estimatedMinutes: 60,
            importance: ImportanceEnum.max,
            dueDate: today,
          );

      final antiga = gemea('z', createdAt: DateTime(2026, 7, 1));
      final nova = gemea('a', createdAt: DateTime(2026, 7, 10));
      final mesmaHora = gemea('b', createdAt: DateTime(2026, 7, 10));

      // Ordem de entrada diferente não muda a saída — a ordem é total.
      expect(
        useCase([nova, mesmaHora, antiga], today).map((l) => l.task.id),
        ['z', 'a', 'b'],
      );
      expect(
        useCase([mesmaHora, antiga, nova], today).map((l) => l.task.id),
        ['z', 'a', 'b'],
      );
    });
  });

  test('monta o subtítulo da hierarquia (mãe › filha)', () {
    final tasks = [
      TaskEntity(
          id: 'mae',
          title: 'Lançar app',
          listId: 'inbox',
          createdAt: today,
          hasChildren: true),
      TaskEntity(
          id: 'filha',
          title: 'Fazer telas',
          listId: 'inbox',
          createdAt: today,
          parentId: 'mae',
          hasChildren: true),
      leaf('neta',
          minutes: 30,
          importance: ImportanceEnum.min,
          dueInDays: 0,
          parentId: 'filha'),
    ];

    final result = useCase(tasks, today);
    expect(result.single.ancestryLabel, 'Lançar app › Fazer telas');
  });
}
