import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/core/error/failures.dart';
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

  // REQ-001: data source succeeds: Right(unit), data source called once with the same values
  test('signUp should return Right when data source succeeds', () async {
    when(
      () => ds.signUp(
        displayName: 'Ana',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    ).thenAnswer((_) async {});

    final result = await repo.signUp(
      displayName: 'Ana',
      email: 'ana@exemplo.com',
      password: 'Abcd1234',
    );

    expect(result, const Right<Failure, Unit>(unit));
    verify(
      () => ds.signUp(
        displayName: 'Ana',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
    ).called(1);
  });

  // REQ-001: data source throws NetworkException / ServerException: Left(NetworkFailure()) / Left(ServerFailure())
  test('signUp should map AppException to failure', () async {
    when(
      () => ds.signUp(
        displayName: any(named: 'displayName'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const NetworkException());
    expect(
      await repo.signUp(
        displayName: 'Ana',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
      const Left<Failure, Unit>(NetworkFailure()),
    );

    when(
      () => ds.signUp(
        displayName: any(named: 'displayName'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const ServerException());
    expect(
      await repo.signUp(
        displayName: 'Ana',
        email: 'ana@exemplo.com',
        password: 'Abcd1234',
      ),
      const Left<Failure, Unit>(ServerFailure()),
    );
  });

  // REQ-005: data source throws EmailAlreadyInUseException: Left(EmailAlreadyInUseFailure())
  test(
    'should return EmailAlreadyInUseFailure when data source throws EmailAlreadyInUseException',
    () async {
      when(
        () => ds.signUp(
          displayName: any(named: 'displayName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const EmailAlreadyInUseException());

      expect(
        await repo.signUp(
          displayName: 'Ana',
          email: 'ana@exemplo.com',
          password: 'Abcd1234',
        ),
        const Left<Failure, Unit>(EmailAlreadyInUseFailure()),
      );
    },
  );

  // REQ-006: data source succeeds: Right(unit), called once with the name
  test(
    'updateDisplayName should return Right(unit) when data source succeeds',
    () async {
      when(() => ds.updateDisplayName('Ana Lima')).thenAnswer((_) async {});

      expect(
        await repo.updateDisplayName('Ana Lima'),
        const Right<Failure, Unit>(unit),
      );
      verify(() => ds.updateDisplayName('Ana Lima')).called(1);
    },
  );

  // REQ-006: data source throws ServerException: Left(ServerFailure())
  test(
    'updateDisplayName should return ServerFailure when data source throws ServerException',
    () async {
      when(
        () => ds.updateDisplayName(any()),
      ).thenThrow(const ServerException());

      expect(
        await repo.updateDisplayName('Ana Lima'),
        const Left<Failure, Unit>(ServerFailure()),
      );
    },
  );

  // REQ-006: data source throws NetworkException / UnauthenticatedException: matching failures
  test('updateDisplayName should map network and session errors', () async {
    when(() => ds.updateDisplayName(any())).thenThrow(const NetworkException());
    expect(
      await repo.updateDisplayName('Ana Lima'),
      const Left<Failure, Unit>(NetworkFailure()),
    );

    when(
      () => ds.updateDisplayName(any()),
    ).thenThrow(const UnauthenticatedException());
    expect(
      await repo.updateDisplayName('Ana Lima'),
      const Left<Failure, Unit>(UnauthenticatedFailure()),
    );
  });

  group('changeEmail', () {
    Future<Either<Failure, Unit>> change() => repo.changeEmail(
      email: 'ana.lima@exemplo.com',
      currentPassword: 'abcd1234',
    );

    void dsThrows(Object error) => when(
      () => ds.changeEmail(
        email: any(named: 'email'),
        currentPassword: any(named: 'currentPassword'),
      ),
    ).thenThrow(error);

    // REQ-007: data source succeeds: Right(unit), called once with the same values
    test(
      'changeEmail should return Right(unit) when data source succeeds',
      () async {
        when(
          () => ds.changeEmail(
            email: 'ana.lima@exemplo.com',
            currentPassword: 'abcd1234',
          ),
        ).thenAnswer((_) async {});

        expect(await change(), const Right<Failure, Unit>(unit));
        verify(
          () => ds.changeEmail(
            email: 'ana.lima@exemplo.com',
            currentPassword: 'abcd1234',
          ),
        ).called(1);
      },
    );

    // REQ-007: WrongCurrentPasswordException becomes WrongCurrentPasswordFailure
    test(
      'changeEmail should return WrongCurrentPasswordFailure when the password is wrong',
      () async {
        dsThrows(const WrongCurrentPasswordException());

        expect(
          await change(),
          const Left<Failure, Unit>(WrongCurrentPasswordFailure()),
        );
      },
    );

    // REQ-007: EmailAlreadyInUseException becomes EmailAlreadyInUseFailure
    test(
      'changeEmail should return EmailAlreadyInUseFailure when the email is taken',
      () async {
        dsThrows(const EmailAlreadyInUseException());

        expect(
          await change(),
          const Left<Failure, Unit>(EmailAlreadyInUseFailure()),
        );
      },
    );

    // REQ-007: NetworkException becomes NetworkFailure
    test(
      'changeEmail should return NetworkFailure when there is no connection',
      () async {
        dsThrows(const NetworkException());

        expect(await change(), const Left<Failure, Unit>(NetworkFailure()));
      },
    );
  });

  group('signOutOtherDevices', () {
    // REQ-009: data source succeeds: Right(unit)
    test(
      'signOutOtherDevices should return Right(unit) when data source succeeds',
      () async {
        when(() => ds.signOutOtherDevices()).thenAnswer((_) async {});

        expect(
          await repo.signOutOtherDevices(),
          const Right<Failure, Unit>(unit),
        );
        verify(() => ds.signOutOtherDevices()).called(1);
      },
    );

    // REQ-009: NetworkException becomes NetworkFailure
    test(
      'signOutOtherDevices should return NetworkFailure when there is no connection',
      () async {
        when(
          () => ds.signOutOtherDevices(),
        ).thenThrow(const NetworkException());

        expect(
          await repo.signOutOtherDevices(),
          const Left<Failure, Unit>(NetworkFailure()),
        );
      },
    );
  });
}
