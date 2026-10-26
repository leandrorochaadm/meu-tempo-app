import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/error/failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:meu_tempo/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:meu_tempo/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignIn extends Mock implements SignInWithEmailUseCase {}

class _MockSignOut extends Mock implements SignOutUseCase {}

class _MockWatch extends Mock implements WatchAuthStateUseCase {}

const _user = UserEntity(uid: 'u1', email: 'a@b.com');
const _params = SignInWithEmailParams(email: 'a@b.com', password: 'x');
const _request = AuthEmailSignInRequested(email: 'a@b.com', password: 'x');

void main() {
  late _MockSignIn signIn;
  late _MockSignOut signOut;
  late _MockWatch watch;
  late StreamController<UserEntity?> controller;

  setUpAll(() {
    registerFallbackValue(_params);
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    signIn = _MockSignIn();
    signOut = _MockSignOut();
    watch = _MockWatch();
    controller = StreamController<UserEntity?>();
    when(() => watch(any())).thenAnswer((_) => controller.stream);
  });

  tearDown(() => controller.close());

  AuthBloc build() => AuthBloc(signIn, signOut, watch);

  blocTest<AuthBloc, AuthState>(
    'should emit only AuthLoading when sign-in succeeds',
    build: build,
    setUp: () =>
        when(() => signIn(any())).thenAnswer((_) async => const Right(unit)),
    act: (b) => b.add(_request),
    expect: () => [const AuthLoading()],
  );

  blocTest<AuthBloc, AuthState>(
    'should emit AuthAuthenticated when stream brings a user',
    build: build,
    act: (b) => controller.add(_user),
    expect: () => [const AuthAuthenticated(_user)],
  );

  blocTest<AuthBloc, AuthState>(
    'should emit AuthUnauthenticated when stream brings null',
    build: build,
    act: (b) => controller.add(null),
    expect: () => [const AuthUnauthenticated()],
  );

  void failTest(String name, Failure failure, String message) {
    blocTest<AuthBloc, AuthState>(
      name,
      build: build,
      setUp: () =>
          when(() => signIn(any())).thenAnswer((_) async => Left(failure)),
      act: (b) => b.add(_request),
      expect: () => [const AuthLoading(), AuthError(message)],
    );
  }

  failTest(
    'should emit AuthError with fill message when credentials are empty',
    const EmptyCredentialsFailure(),
    'Preencha o e-mail e a senha.',
  );
  failTest(
    'should emit wrong credentials message on AuthFailure',
    const AuthFailure(),
    'E-mail ou senha incorretos.',
  );
  failTest(
    'should emit no connection message on NetworkFailure',
    const NetworkFailure(),
    'Sem conexão. Verifique a internet.',
  );
  failTest(
    'should emit generic message on ServerFailure',
    const ServerFailure(),
    'Não foi possível entrar. Tente novamente.',
  );

  test('should emit generic AuthError when sign-in times out', () {
    fakeAsync((async) {
      when(
        () => signIn(any()),
      ).thenAnswer((_) => Completer<Either<Failure, Unit>>().future);
      final bloc = build();
      final states = <AuthState>[];
      bloc.stream.listen(states.add);
      bloc.add(_request);
      async.elapse(const Duration(seconds: 31));
      expect(states, [
        const AuthLoading(),
        const AuthError('Não foi possível entrar. Tente novamente.'),
      ]);
      bloc.close();
    });
  });

  blocTest<AuthBloc, AuthState>(
    'should not emit error when sign-out succeeds',
    build: build,
    setUp: () =>
        when(() => signOut(any())).thenAnswer((_) async => const Right(unit)),
    act: (b) => b.add(const AuthSignOutRequested()),
    expect: () => <AuthState>[],
  );

  blocTest<AuthBloc, AuthState>(
    'should emit AuthError when sign-out fails',
    build: build,
    setUp: () => when(
      () => signOut(any()),
    ).thenAnswer((_) async => const Left(AuthFailure())),
    act: (b) => b.add(const AuthSignOutRequested()),
    expect: () => [const AuthError('E-mail ou senha incorretos.')],
  );
}
