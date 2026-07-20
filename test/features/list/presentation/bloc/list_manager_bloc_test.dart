import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/list/domain/entities/task_list_entity.dart';
import 'package:meu_tempo/features/list/domain/usecases/create_list_use_case.dart';
import 'package:meu_tempo/features/list/domain/usecases/delete_list_use_case.dart';
import 'package:meu_tempo/features/list/domain/usecases/rename_list_use_case.dart';
import 'package:meu_tempo/features/list/domain/usecases/watch_lists_use_case.dart';
import 'package:meu_tempo/features/list/presentation/bloc/list_manager_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchLists extends Mock implements WatchListsUseCase {}

class _MockCreateList extends Mock implements CreateListUseCase {}

class _MockRenameList extends Mock implements RenameListUseCase {}

class _MockDeleteList extends Mock implements DeleteListUseCase {}

class _FakeCreateParams extends Fake implements CreateListParams {}

class _FakeRenameParams extends Fake implements RenameListParams {}

class _FakeDeleteParams extends Fake implements DeleteListParams {}

class _FakeNoParams extends Fake implements NoParams {}

void main() {
  late _MockWatchLists watchLists;
  late _MockCreateList createList;
  late _MockRenameList renameList;
  late _MockDeleteList deleteList;

  const list = TaskListEntity(id: 'inbox', name: 'Entrada', isDefault: true);

  setUpAll(() {
    registerFallbackValue(_FakeCreateParams());
    registerFallbackValue(_FakeRenameParams());
    registerFallbackValue(_FakeDeleteParams());
    registerFallbackValue(_FakeNoParams());
  });

  setUp(() {
    watchLists = _MockWatchLists();
    createList = _MockCreateList();
    renameList = _MockRenameList();
    deleteList = _MockDeleteList();
  });

  ListManagerBloc build() =>
      ListManagerBloc(watchLists, createList, renameList, deleteList);

  blocTest<ListManagerBloc, ListManagerState>(
    'started emite [Loading, Loaded]',
    build: () {
      when(() => watchLists(any()))
          .thenAnswer((_) => Stream.value(const Right([list])));
      return build();
    },
    act: (bloc) => bloc.add(const ListManagerStarted()),
    expect: () => [
      const ListManagerLoading(),
      const ListManagerLoaded([list]),
    ],
  );

  blocTest<ListManagerBloc, ListManagerState>(
    'ListCreated delega ao CreateListUseCase',
    build: () {
      when(() => watchLists(any()))
          .thenAnswer((_) => Stream.value(const Right([list])));
      when(() => createList(any()))
          .thenAnswer((_) async => const Right(list));
      return build();
    },
    act: (bloc) async {
      bloc.add(const ListManagerStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ListCreated('Estudo'));
    },
    verify: (_) {
      final p = verify(() => createList(captureAny())).captured.single
          as CreateListParams;
      expect(p.name, 'Estudo');
    },
  );

  blocTest<ListManagerBloc, ListManagerState>(
    'ListDeleted delega ao DeleteListUseCase e propaga erro',
    build: () {
      when(() => watchLists(any()))
          .thenAnswer((_) => Stream.value(const Right([list])));
      when(() => deleteList(any()))
          .thenAnswer((_) async => const Left(NetworkFailure()));
      return build();
    },
    act: (bloc) async {
      bloc.add(const ListManagerStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ListDeleted(listId: 'x', moveToListId: 'inbox'));
    },
    expect: () => [
      const ListManagerLoading(),
      const ListManagerLoaded([list]),
      isA<ListManagerError>(),
    ],
  );
}
