import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_tempo/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AuthRepository {}

void main() {
  late _MockRepository repo;
  late SignInWithEmailUseCase useCase;

  setUp(() {
    repo = _MockRepository();
    useCase = SignInWithEmailUseCase(repo);
    when(
      () => repo.signInWithEmail(any(), any()),
    ).thenAnswer((_) async => const Right(unit));
  });

  test('should trim email before calling repository', () async {
    await useCase(
      const SignInWithEmailParams(email: ' a@b.com ', password: 'x'),
    );
    verify(() => repo.signInWithEmail('a@b.com', 'x')).called(1);
  });

  test('should keep password unchanged', () async {
    await useCase(
      const SignInWithEmailParams(email: 'a@b.com', password: ' x '),
    );
    verify(() => repo.signInWithEmail('a@b.com', ' x ')).called(1);
  });

  test('should return EmptyCredentialsFailure when email is blank', () async {
    final r = await useCase(
      const SignInWithEmailParams(email: '   ', password: 'x'),
    );
    expect(r.getLeft().toNullable(), isA<EmptyCredentialsFailure>());
    verifyNever(() => repo.signInWithEmail(any(), any()));
  });

  test(
    'should return EmptyCredentialsFailure when password is empty',
    () async {
      final r = await useCase(
        const SignInWithEmailParams(email: 'a@b.com', password: ''),
      );
      expect(r.getLeft().toNullable(), isA<EmptyCredentialsFailure>());
      verifyNever(() => repo.signInWithEmail(any(), any()));
    },
  );
}
