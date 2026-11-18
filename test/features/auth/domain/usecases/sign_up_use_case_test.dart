import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/account_field_error_enum.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
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

  // REQ-002: Sign up, name "A" (1 character): rejected with displayNameLength, repository not called
  test(
    'should return InvalidAccountFieldsFailure([displayNameLength]) and not call repository when name is "A"',
    () async {
      final result = await useCase(
        SignUpParams(
          displayName: 'A',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
        ),
      );

      expect(
        result,
        Left<Failure, Unit>(
          InvalidAccountFieldsFailure([
            AccountFieldErrorEnum.displayNameLength,
          ]),
        ),
      );
      verifyNever(
        () => repo.signUp(
          displayName: any(named: 'displayName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    },
  );

  // REQ-002: Sign up, name "Al" (2 characters): accepted, repository receives "Al"
  test('should call repository with "Al" when name has 2 characters', () async {
    final result = await useCase(
      SignUpParams(
        displayName: 'Al',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(
      () => repo.signUp(
        displayName: 'Al',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    ).called(1);
  });

  // REQ-002: Sign up, name "Ana" (3 characters): accepted, repository receives "Ana"
  test(
    'should call repository with "Ana" when name has 3 characters',
    () async {
      final result = await useCase(
        SignUpParams(
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

  // REQ-002: Sign up, name "A B" (inner space counts): accepted, repository receives "A B"
  test('should accept "A B" counting the inner space', () async {
    final result = await useCase(
      SignUpParams(
        displayName: 'A B',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(
      () => repo.signUp(
        displayName: 'A B',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    ).called(1);
  });

  // REQ-002: Sign up, name "   " (only spaces): rejected with displayNameLength, repository not called
  test('should reject name with only spaces', () async {
    final result = await useCase(
      SignUpParams(
        displayName: '   ',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    );

    expect(
      result,
      Left<Failure, Unit>(
        InvalidAccountFieldsFailure([AccountFieldErrorEnum.displayNameLength]),
      ),
    );
    verifyNever(
      () => repo.signUp(
        displayName: any(named: 'displayName'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  // REQ-002: Sign up, name " A ": rejected with displayNameLength, repository not called
  test('should reject " A " after trimming', () async {
    final result = await useCase(
      SignUpParams(
        displayName: ' A ',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    );

    expect(
      result,
      Left<Failure, Unit>(
        InvalidAccountFieldsFailure([AccountFieldErrorEnum.displayNameLength]),
      ),
    );
    verifyNever(
      () => repo.signUp(
        displayName: any(named: 'displayName'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  // REQ-002: Sign up, name "😀😀" (2 emojis): accepted as 2 characters
  test('should accept two emojis as 2 characters', () async {
    final result = await useCase(
      SignUpParams(
        displayName: '😀😀',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(
      () => repo.signUp(
        displayName: '😀😀',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    ).called(1);
  });

  // REQ-002: Sign up, name "😀" (1 emoji): rejected with displayNameLength, repository not called
  test('should reject a single emoji', () async {
    final result = await useCase(
      SignUpParams(
        displayName: '😀',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    );

    expect(
      result,
      Left<Failure, Unit>(
        InvalidAccountFieldsFailure([AccountFieldErrorEnum.displayNameLength]),
      ),
    );
    verifyNever(
      () => repo.signUp(
        displayName: any(named: 'displayName'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  // REQ-002: Sign up, name "José" with "e" + combining accent (4 characters): accepted, repository receives the name unchanged
  test('should accept José with combining accent as 4 characters', () async {
    final result = await useCase(
      SignUpParams(
        displayName: 'Jose\u0301',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(
      () => repo.signUp(
        displayName: 'Jose\u0301',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    ).called(1);
  });

  // REQ-002: Sign up, name with 51 characters: rejected with displayNameLength, repository not called
  test('should reject 51 characters without calling repository', () async {
    final result = await useCase(
      SignUpParams(
        displayName: 'a' * 51,
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    );

    expect(
      result,
      Left<Failure, Unit>(
        InvalidAccountFieldsFailure([AccountFieldErrorEnum.displayNameLength]),
      ),
    );
    verifyNever(
      () => repo.signUp(
        displayName: any(named: 'displayName'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
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
