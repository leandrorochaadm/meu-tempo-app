import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/features/auth/domain/repositories/auth_repository.dart';
import 'package:meu_tempo/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements AuthRepository {}

void main() {
  late _MockRepository repo;
  late SignUpUseCase useCase;

  setUp(() {
    repo = _MockRepository();
    useCase = SignUpUseCase(repo);
    when(
      () => repo.signUp(
        displayName: any(named: 'displayName'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  // REQ-001: Name "Ana", email "ana@exemplo.com", password "Abcd1234": repository called once with the same values
  test(
    'should call repository once with name, email and password when data is valid',
    () async {
      final result = await useCase(
        const SignUpParams(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
        ),
      );

      expect(result, const Right<Failure, Unit>(unit));
      verify(
        () => repo.signUp(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
        ),
      ).called(1);
    },
  );

  // REQ-001: Name "  Ana  ", email " Ana@Exemplo.com ": repository called once with "Ana" and "ana@exemplo.com"
  test(
    'should trim name and normalize email before calling repository',
    () async {
      await useCase(
        const SignUpParams(
          displayName: '  Ana  ',
          email: ' Ana@Exemplo.com ',
          password: 'Abcd1234',
        ),
      );

      verify(
        () => repo.signUp(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
        ),
      ).called(1);
    },
  );

  // REQ-001: Password " Abcd123" (leading space): repository receives it unchanged
  test('should pass password exactly as typed', () async {
    await useCase(
      const SignUpParams(
        displayName: 'Ana',
        email: 'ana@exemplo.com',
        password: ' Abcd123',
      ),
    );

    verify(
      () => repo.signUp(
        displayName: 'Ana',
        email: 'ana@exemplo.com',
        password: ' Abcd123',
      ),
    ).called(1);
  });

  // REQ-001: Name "A B" (inner space): repository receives "A B"
  test('should keep inner spaces of name', () async {
    await useCase(
      const SignUpParams(
        displayName: 'A B',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    );

    verify(
      () => repo.signUp(
        displayName: 'A B',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    ).called(1);
  });

  // REQ-001: repository returns NetworkFailure: use case returns Left(NetworkFailure()) after 1 call
  test('should return repository failure unchanged', () async {
    when(
      () => repo.signUp(
        displayName: any(named: 'displayName'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await useCase(
      const SignUpParams(
        displayName: 'Ana',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    );

    expect(result, const Left<Failure, Unit>(NetworkFailure()));
    verify(
      () => repo.signUp(
        displayName: any(named: 'displayName'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).called(1);
  });

  // REQ-001: equal SignUpParams are equal; changing one field at a time makes them different
  test('should compare SignUpParams by value', () {
    const base = SignUpParams(
      displayName: 'Ana',
      email: 'ana@exemplo.com',
      password: 'Abcd1234',
    );
    const same = SignUpParams(
      displayName: 'Ana',
      email: 'ana@exemplo.com',
      password: 'Abcd1234',
    );

    expect(base, same);
    expect(base.hashCode, same.hashCode);
    expect(
      base,
      isNot(
        const SignUpParams(
          displayName: 'Bia',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
        ),
      ),
    );
    expect(
      base,
      isNot(
        const SignUpParams(
          displayName: 'Ana',
          email: 'bia@exemplo.com',
          password: 'Abcd1234',
        ),
      ),
    );
    expect(
      base,
      isNot(
        const SignUpParams(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: 'Abcd12345',
        ),
      ),
    );
  });
}
