import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meu_tempo/core/error/auth_failures.dart';
import 'package:meu_tempo/core/usecase/usecase.dart';
import 'package:meu_tempo/features/auth/domain/entities/user_entity.dart';
import 'package:meu_tempo/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:meu_tempo/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:meu_tempo/features/auth/domain/usecases/watch_auth_state_use_case.dart';
import 'package:meu_tempo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignIn extends Mock implements SignInWithGoogleUseCase {}

class _MockSignOut extends Mock implements SignOutUseCase {}

class _MockWatchAuth extends Mock implements WatchAuthStateUseCase {}

class _FakeNoParams extends Fake implements NoParams {}

void main() {
  late _MockSignIn signIn;
  late _MockSignOut signOut;
  late _MockWatchAuth watchAuth;

  const user = UserEntity(uid: 'u1', email: 'a@b.com');

  setUpAll(() => registerFallbackValue(_FakeNoParams()));

  setUp(() {
    signIn = _MockSignIn();
    signOut = _MockSignOut();
    watchAuth = _MockWatchAuth();
    when(() => watchAuth(any())).thenAnswer((_) => const Stream.empty());
  });

  AuthBloc build() => AuthBloc(signIn, signOut, watchAuth);

  blocTest<AuthBloc, AuthState>(
    'emite AuthAuthenticated quando o stream traz um usuário',
    build: () {
      when(() => watchAuth(any())).thenAnswer((_) => Stream.value(user));
      return build();
    },
    expect: () => [const AuthAuthenticated(user)],
  );

  blocTest<AuthBloc, AuthState>(
    'emite AuthUnauthenticated quando o stream traz null',
    build: () {
      when(() => watchAuth(any())).thenAnswer((_) => Stream.value(null));
      return build();
    },
    expect: () => [const AuthUnauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'sign-in cancelado emite [Loading, AuthError]',
    build: () {
      when(() => signIn(any()))
          .thenAnswer((_) async => const Left(SignInCancelledFailure()));
      return build();
    },
    act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
    expect: () => [
      const AuthLoading(),
      const AuthError('Login cancelado.'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'sign-in com sucesso emite só [Loading] (usuário vem pelo stream)',
    build: () {
      when(() => signIn(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
    expect: () => [const AuthLoading()],
  );

  blocTest<AuthBloc, AuthState>(
    'sign-out com sucesso não emite estado de erro',
    build: () {
      when(() => signOut(any())).thenAnswer((_) async => const Right(unit));
      return build();
    },
    act: (bloc) => bloc.add(const AuthSignOutRequested()),
    expect: () => const <AuthState>[],
  );

  blocTest<AuthBloc, AuthState>(
    'sign-out com falha emite AuthError',
    build: () {
      when(() => signOut(any())).thenAnswer((_) async => const Left(AuthFailure()));
      return build();
    },
    act: (bloc) => bloc.add(const AuthSignOutRequested()),
    expect: () => [isA<AuthError>()],
  );
}
