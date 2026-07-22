import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_tempo/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:meu_tempo/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:meu_tempo/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  const user = UserEntity(uid: 'u1', email: 'a@b.com');

  setUp(() => repository = _MockAuthRepository());

  test('SignInWithGoogleUseCase delega ao repositório', () async {
    when(() => repository.signInWithGoogle())
        .thenAnswer((_) async => const Right(unit));

    final result = await SignInWithGoogleUseCase(repository)(const NoParams());

    expect(result.isRight(), isTrue);
    verify(() => repository.signInWithGoogle()).called(1);
  });

  test('SignOutUseCase delega ao repositório', () async {
    when(() => repository.signOut()).thenAnswer((_) async => const Right(unit));

    final result = await SignOutUseCase(repository)(const NoParams());

    expect(result.isRight(), isTrue);
    verify(() => repository.signOut()).called(1);
  });

  test('WatchAuthStateUseCase repassa o stream do repositório', () {
    when(() => repository.authState()).thenAnswer((_) => Stream.value(user));

    final stream = WatchAuthStateUseCase(repository)(const NoParams());

    expect(stream, emits(user));
  });
}
