import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_tempo/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:meu_tempo/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AuthRepository {}

void main() {
  late _MockRepository repo;
  setUp(() => repo = _MockRepository());

  test('should delegate sign-out to repository', () async {
    when(() => repo.signOut()).thenAnswer((_) async => const Right(unit));
    expect(await SignOutUseCase(repo)(const NoParams()), const Right(unit));
    verify(() => repo.signOut()).called(1);
  });

  test('should forward auth state stream', () async {
    const user = UserEntity(uid: 'u1', email: 'a@b.com');
    when(
      () => repo.authState(),
    ).thenAnswer((_) => Stream.fromIterable([user, null]));
    final values = await WatchAuthStateUseCase(repo)(const NoParams()).toList();
    expect(values, [user, null]);
  });
}
