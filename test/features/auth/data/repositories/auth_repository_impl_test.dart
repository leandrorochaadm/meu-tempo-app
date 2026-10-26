import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:meu_tempo/features/auth/data/models/user_model.dart';
import 'package:meu_tempo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late _MockDataSource ds;
  late AuthRepositoryImpl repo;
  const model = UserModel(uid: 'u1', email: 'a@b.com');

  setUp(() {
    ds = _MockDataSource();
    repo = AuthRepositoryImpl(ds);
  });

  test('should return Right on sign-in success', () async {
    when(() => ds.signInWithEmail('a@b.com', 'x')).thenAnswer((_) async {});
    expect(await repo.signInWithEmail('a@b.com', 'x'), const Right(unit));
  });

  test(
    'should return AuthFailure when datasource throws AuthException',
    () async {
      when(
        () => ds.signInWithEmail(any(), any()),
      ).thenThrow(const AuthException());
      final result = await repo.signInWithEmail('a@b.com', 'x');
      expect(result.getLeft().toNullable(), isA<AuthFailure>());
    },
  );

  test('should return Right on sign out', () async {
    when(() => ds.signOut()).thenAnswer((_) async {});
    expect(await repo.signOut(), const Right(unit));
  });

  test('should map models to entities in authState', () async {
    when(
      () => ds.authState(),
    ).thenAnswer((_) => Stream.fromIterable([model, null]));
    when(() => ds.currentUser()).thenReturn(model);
    final values = await repo.authState().toList();
    expect(values.first?.uid, 'u1');
    expect(values.last, isNull);
    expect(repo.currentUser()?.email, 'a@b.com');
  });
}
