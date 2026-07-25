import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/task/domain/entities/task_entity.dart';
import 'package:meu_tempo/features/task/domain/repositories/task_repository.dart';
import 'package:meu_tempo/features/task/domain/usecases/delete_task_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepo extends Mock implements TaskRepository {}

void main() {
  late _MockTaskRepo repo;
  final today = DateTime(2026, 7, 20);

  setUp(() {
    repo = _MockTaskRepo();
    when(() => repo.deleteSubtree(
          any(),
          emptiedParentId: any(named: 'emptiedParentId'),
        )).thenAnswer((_) async => const Right(unit));
  });

  TaskEntity t(String id, {String? parentId, bool hasChildren = false}) =>
      TaskEntity(
        id: id,
        title: id,
        listId: 'inbox',
        createdAt: today,
        parentId: parentId,
        hasChildren: hasChildren,
      );

  /// Captura a chamada atômica: ids excluídos + pai liberado (`null` = nenhum).
  /// `verify` consome as interações, então chame **uma vez** por teste.
  ({List<String> ids, String? emptiedParent}) captureDelete() {
    final captured = verify(() => repo.deleteSubtree(
          captureAny(),
          emptiedParentId: captureAny(named: 'emptiedParentId'),
        )).captured;
    return (
      ids: captured[0] as List<String>,
      emptiedParent: captured[1] as String?,
    );
  }

  test('exclui a tarefa e todos os descendentes (cascata)', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('mae', hasChildren: true),
          t('filha', parentId: 'mae', hasChildren: true),
          t('neta', parentId: 'filha'),
          t('outra'),
        ]));

    await DeleteTaskUseCase(repo)(const DeleteTaskParams(taskId: 'mae'));

    final call = captureDelete();
    expect(call.ids, containsAll(['mae', 'filha', 'neta']));
    expect(call.ids, isNot(contains('outra')));
  });

  test('a cascata inteira vai numa única escrita atômica', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('mae', hasChildren: true),
          t('filha', parentId: 'mae', hasChildren: true),
          t('neta', parentId: 'filha'),
        ]));

    await DeleteTaskUseCase(repo)(const DeleteTaskParams(taskId: 'mae'));

    // Um só commit — nunca N chamadas soltas de delete.
    verify(() => repo.deleteSubtree(
          any(),
          emptiedParentId: any(named: 'emptiedParentId'),
        )).called(1);
    verifyNever(() => repo.delete(any()));
  });

  test('libera o pai (mesma escrita) quando ele fica sem filhas', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('mae', hasChildren: true),
          t('unica', parentId: 'mae'),
        ]));

    await DeleteTaskUseCase(repo)(const DeleteTaskParams(taskId: 'unica'));

    final call = captureDelete();
    expect(call.ids, ['unica']);
    expect(call.emptiedParent, 'mae');
  });

  test('não libera o pai quando ainda restam outras filhas', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('mae', hasChildren: true),
          t('f1', parentId: 'mae'),
          t('f2', parentId: 'mae'),
        ]));

    await DeleteTaskUseCase(repo)(const DeleteTaskParams(taskId: 'f1'));

    expect(captureDelete().emptiedParent, isNull);
  });

  test('tarefa raiz (sem pai) não pede liberação de pai', () async {
    when(() => repo.getTasks())
        .thenAnswer((_) async => Right([t('solta'), t('outra')]));

    await DeleteTaskUseCase(repo)(const DeleteTaskParams(taskId: 'solta'));

    final call = captureDelete();
    expect(call.ids, ['solta']);
    expect(call.emptiedParent, isNull);
  });

  test('devolve a subárvore removida com a raiz primeiro (para o undo)',
      () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([
          t('mae', hasChildren: true),
          t('filha', parentId: 'mae', hasChildren: true),
          t('neta', parentId: 'filha'),
        ]));

    final result =
        await DeleteTaskUseCase(repo)(const DeleteTaskParams(taskId: 'mae'));

    final removed = result.getRight().toNullable()!;
    expect(removed.first.id, 'mae');
    expect(removed.map((t) => t.id), containsAll(['mae', 'filha', 'neta']));
  });

  test('falha na leitura das tarefas não tenta excluir nada', () async {
    when(() => repo.getTasks())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result =
        await DeleteTaskUseCase(repo)(const DeleteTaskParams(taskId: 'x'));

    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    verifyNever(() => repo.deleteSubtree(
          any(),
          emptiedParentId: any(named: 'emptiedParentId'),
        ));
  });

  test('propaga o Failure da escrita atômica', () async {
    when(() => repo.getTasks()).thenAnswer((_) async => Right([t('solta')]));
    when(() => repo.deleteSubtree(
          any(),
          emptiedParentId: any(named: 'emptiedParentId'),
        )).thenAnswer((_) async => const Left(PermissionDeniedFailure()));

    final result =
        await DeleteTaskUseCase(repo)(const DeleteTaskParams(taskId: 'solta'));

    expect(result.getLeft().toNullable(), isA<PermissionDeniedFailure>());
  });
}
