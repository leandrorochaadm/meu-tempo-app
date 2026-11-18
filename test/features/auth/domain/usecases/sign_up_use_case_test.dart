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

  // REQ-010: Sign up, E-mail "ana@exemplo.com": accepted, repository called once
  test('should call repository once when email is ana@exemplo.com', () async {
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
  });

  // REQ-010: Sign up, E-mail "a@b.co": accepted, repository called once
  test('should call repository once when email is a@b.co', () async {
    final result = await useCase(
      SignUpParams(displayName: 'Ana', email: 'a@b.co', password: 'Abcd1234'),
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(
      () => repo.signUp(
        displayName: 'Ana',
        email: 'a@b.co',
        password: 'Abcd1234',
      ),
    ).called(1);
  });

  // REQ-010: Sign up, E-mail "ana@": rejected with invalidEmail, repository not called
  test(
    'should return invalidEmail and not call repository when email is ana@',
    () async {
      final result = await useCase(
        SignUpParams(displayName: 'Ana', email: 'ana@', password: 'Abcd1234'),
      );

      expect(
        result,
        Left<Failure, Unit>(
          InvalidAccountFieldsFailure([AccountFieldErrorEnum.invalidEmail]),
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

  // REQ-010: Sign up, E-mail "ana.exemplo.com" (no "@"): rejected with invalidEmail, repository not called
  test(
    'should return invalidEmail and not call repository when email is ana.exemplo.com',
    () async {
      final result = await useCase(
        SignUpParams(
          displayName: 'Ana',
          email: 'ana.exemplo.com',
          password: 'Abcd1234',
        ),
      );

      expect(
        result,
        Left<Failure, Unit>(
          InvalidAccountFieldsFailure([AccountFieldErrorEnum.invalidEmail]),
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

  // REQ-010: Sign up, Empty e-mail: rejected with invalidEmail, repository not called
  test(
    'should return invalidEmail and not call repository when email is empty',
    () async {
      final result = await useCase(
        SignUpParams(displayName: 'Ana', email: '', password: 'Abcd1234'),
      );

      expect(
        result,
        Left<Failure, Unit>(
          InvalidAccountFieldsFailure([AccountFieldErrorEnum.invalidEmail]),
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

  // REQ-010: Sign up, E-mail "@exemplo.com" (nothing before "@"): rejected with invalidEmail, repository not called
  test(
    'should return invalidEmail and not call repository when email is @exemplo.com',
    () async {
      final result = await useCase(
        SignUpParams(
          displayName: 'Ana',
          email: '@exemplo.com',
          password: 'Abcd1234',
        ),
      );

      expect(
        result,
        Left<Failure, Unit>(
          InvalidAccountFieldsFailure([AccountFieldErrorEnum.invalidEmail]),
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

  // REQ-010: Sign up, E-mail "ana@@exemplo.com" (two "@"): rejected with invalidEmail, repository not called
  test(
    'should return invalidEmail and not call repository when email is ana@@exemplo.com',
    () async {
      final result = await useCase(
        SignUpParams(
          displayName: 'Ana',
          email: 'ana@@exemplo.com',
          password: 'Abcd1234',
        ),
      );

      expect(
        result,
        Left<Failure, Unit>(
          InvalidAccountFieldsFailure([AccountFieldErrorEnum.invalidEmail]),
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

  // REQ-010: Sign up, E-mail "ana@exemplo" (domain without dot): rejected with invalidEmail, repository not called
  test(
    'should return invalidEmail and not call repository when email is ana@exemplo',
    () async {
      final result = await useCase(
        SignUpParams(
          displayName: 'Ana',
          email: 'ana@exemplo',
          password: 'Abcd1234',
        ),
      );

      expect(
        result,
        Left<Failure, Unit>(
          InvalidAccountFieldsFailure([AccountFieldErrorEnum.invalidEmail]),
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

  // REQ-010: Sign up, E-mail "ana@exemplo." (dot at the end): rejected with invalidEmail, repository not called
  test(
    'should return invalidEmail and not call repository when email is ana@exemplo.',
    () async {
      final result = await useCase(
        SignUpParams(
          displayName: 'Ana',
          email: 'ana@exemplo.',
          password: 'Abcd1234',
        ),
      );

      expect(
        result,
        Left<Failure, Unit>(
          InvalidAccountFieldsFailure([AccountFieldErrorEnum.invalidEmail]),
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

  // REQ-010: Sign up, E-mail "ana@.exemplo.com" (dot at the start of the domain): rejected with invalidEmail, repository not called
  test(
    'should return invalidEmail and not call repository when email is ana@.exemplo.com',
    () async {
      final result = await useCase(
        SignUpParams(
          displayName: 'Ana',
          email: 'ana@.exemplo.com',
          password: 'Abcd1234',
        ),
      );

      expect(
        result,
        Left<Failure, Unit>(
          InvalidAccountFieldsFailure([AccountFieldErrorEnum.invalidEmail]),
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

  // REQ-010: Sign up, E-mail "ana @exemplo.com" (inner space): rejected with invalidEmail, repository not called
  test(
    'should return invalidEmail and not call repository when email is ana @exemplo.com',
    () async {
      final result = await useCase(
        SignUpParams(
          displayName: 'Ana',
          email: 'ana @exemplo.com',
          password: 'Abcd1234',
        ),
      );

      expect(
        result,
        Left<Failure, Unit>(
          InvalidAccountFieldsFailure([AccountFieldErrorEnum.invalidEmail]),
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

  // REQ-010: Sign up, E-mail "ana@exemplo..com" (two dots in a row in the domain): rejected with invalidEmail, repository not called
  test(
    'should return invalidEmail and not call repository when email is ana@exemplo..com',
    () async {
      final result = await useCase(
        SignUpParams(
          displayName: 'Ana',
          email: 'ana@exemplo..com',
          password: 'Abcd1234',
        ),
      );

      expect(
        result,
        Left<Failure, Unit>(
          InvalidAccountFieldsFailure([AccountFieldErrorEnum.invalidEmail]),
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

  // REQ-010: Sign up, E-mail "ana..lima@exemplo.com" (two dots in a row before "@"): rejected with invalidEmail, repository not called
  test(
    'should return invalidEmail and not call repository when email is ana..lima@exemplo.com',
    () async {
      final result = await useCase(
        SignUpParams(
          displayName: 'Ana',
          email: 'ana..lima@exemplo.com',
          password: 'Abcd1234',
        ),
      );

      expect(
        result,
        Left<Failure, Unit>(
          InvalidAccountFieldsFailure([AccountFieldErrorEnum.invalidEmail]),
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

  // REQ-010: Sign up, E-mail "ana.lima@exemplo.com.br" (separate dots): accepted, repository called once
  test(
    'should call repository once when email is ana.lima@exemplo.com.br',
    () async {
      final result = await useCase(
        SignUpParams(
          displayName: 'Ana',
          email: 'ana.lima@exemplo.com.br',
          password: 'Abcd1234',
        ),
      );

      expect(result, const Right<Failure, Unit>(unit));
      verify(
        () => repo.signUp(
          displayName: 'Ana',
          email: 'ana.lima@exemplo.com.br',
          password: 'Abcd1234',
        ),
      ).called(1);
    },
  );

  // REQ-010, REQ-011: Name "A" and e-mail "ana@" together: both errors in field order (name, then e-mail), repository not called
  test('should return name and email errors together in field order', () async {
    final result = await useCase(
      SignUpParams(displayName: 'A', email: 'ana@', password: 'Abcd1234'),
    );

    expect(
      result,
      Left<Failure, Unit>(
        InvalidAccountFieldsFailure([
          AccountFieldErrorEnum.displayNameLength,
          AccountFieldErrorEnum.invalidEmail,
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
  });

  group('password rules', () {
    Future<Either<Failure, Unit>> signUpWith(String password) => useCase(
      SignUpParams(
        displayName: 'Ana',
        email: 'ana@exemplo.com',
        password: password,
      ),
    );

    void expectRepositoryNotCalled() {
      verifyNever(
        () => repo.signUp(
          displayName: any(named: 'displayName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    }

    void expectRepositoryCalledOnce(String password) {
      verify(
        () => repo.signUp(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: password,
        ),
      ).called(1);
    }

    Left<Failure, Unit> rejected(List<AccountFieldErrorEnum> errors) =>
        Left<Failure, Unit>(InvalidAccountFieldsFailure(errors));

    // REQ-003: Sign up, Password "Abcd123" (7 characters): rejected with passwordTooShort, repository not called
    test(
      'should reject 7-character password without calling repository',
      () async {
        final result = await signUpWith('Abcd123');

        expect(result, rejected([AccountFieldErrorEnum.passwordTooShort]));
        expectRepositoryNotCalled();
      },
    );

    // REQ-003: Sign up, empty Password: 4 errors, repository not called
    test(
      'should reject empty password with 4 errors without calling repository',
      () async {
        final result = await signUpWith('');

        expect(
          result,
          rejected([
            AccountFieldErrorEnum.passwordTooShort,
            AccountFieldErrorEnum.passwordMissingDigit,
            AccountFieldErrorEnum.passwordMissingUppercase,
            AccountFieldErrorEnum.passwordMissingLowercase,
          ]),
        );
        expectRepositoryNotCalled();
      },
    );

    // REQ-003: Sign up, Password with 71 characters (limit): accepted, repository called once
    test('should call repository once with 71-character password', () async {
      final password = 'Ab1${'x' * 68}';
      final result = await signUpWith(password);

      expect(result, const Right<Failure, Unit>(unit));
      expectRepositoryCalledOnce(password);
    });

    // REQ-003: Sign up, Password with 72 characters: rejected with passwordTooLong, repository not called
    test(
      'should reject 72-character password without calling repository',
      () async {
        final result = await signUpWith('Ab1${'x' * 69}');

        expect(result, rejected([AccountFieldErrorEnum.passwordTooLong]));
        expectRepositoryNotCalled();
      },
    );

    // REQ-003: Sign up, Password "Abcdefgh" (no digit): rejected with passwordMissingDigit, repository not called
    test(
      'should reject password without digit without calling repository',
      () async {
        final result = await signUpWith('Abcdefgh');

        expect(result, rejected([AccountFieldErrorEnum.passwordMissingDigit]));
        expectRepositoryNotCalled();
      },
    );

    // REQ-003: Sign up, Password "abcd1234" (no uppercase): rejected with passwordMissingUppercase, repository not called
    test(
      'should reject password without uppercase without calling repository',
      () async {
        final result = await signUpWith('abcd1234');

        expect(
          result,
          rejected([AccountFieldErrorEnum.passwordMissingUppercase]),
        );
        expectRepositoryNotCalled();
      },
    );

    // REQ-003: Sign up, Password "ABCD1234" (no lowercase): rejected with passwordMissingLowercase, repository not called
    test(
      'should reject password without lowercase without calling repository',
      () async {
        final result = await signUpWith('ABCD1234');

        expect(
          result,
          rejected([AccountFieldErrorEnum.passwordMissingLowercase]),
        );
        expectRepositoryNotCalled();
      },
    );

    // REQ-003: Sign up, Password "Ébcd1234" (accented uppercase): accepted, repository called once
    test('should call repository once with Ébcd1234', () async {
      final result = await signUpWith('Ébcd1234');

      expect(result, const Right<Failure, Unit>(unit));
      expectRepositoryCalledOnce('Ébcd1234');
    });

    // REQ-003: Sign up, Password "ABCDé123" (accented lowercase): accepted, repository called once
    test('should call repository once with ABCDé123', () async {
      final result = await signUpWith('ABCDé123');

      expect(result, const Right<Failure, Unit>(unit));
      expectRepositoryCalledOnce('ABCDé123');
    });

    // REQ-003: Sign up, Password with 8 spaces: 3 errors, repository not called
    test(
      'should reject 8 spaces with 3 errors without calling repository',
      () async {
        final result = await signUpWith('        ');

        expect(
          result,
          rejected([
            AccountFieldErrorEnum.passwordMissingDigit,
            AccountFieldErrorEnum.passwordMissingUppercase,
            AccountFieldErrorEnum.passwordMissingLowercase,
          ]),
        );
        expectRepositoryNotCalled();
      },
    );

    // REQ-003, REQ-011: Sign up, Name "A", E-mail "ana@" and Password "abc" together: errors in field order (name, e-mail, password)
    test(
      'should return name, email and password errors in field order',
      () async {
        final result = await useCase(
          const SignUpParams(displayName: 'A', email: 'ana@', password: 'abc'),
        );

        expect(
          result,
          rejected([
            AccountFieldErrorEnum.displayNameLength,
            AccountFieldErrorEnum.invalidEmail,
            AccountFieldErrorEnum.passwordTooShort,
            AccountFieldErrorEnum.passwordMissingDigit,
            AccountFieldErrorEnum.passwordMissingUppercase,
          ]),
        );
        expectRepositoryNotCalled();
      },
    );
  });
}
