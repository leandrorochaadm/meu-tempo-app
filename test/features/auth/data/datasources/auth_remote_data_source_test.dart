import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _FakeAuthProvider extends Fake implements AuthProvider {}

void main() {
  late _MockFirebaseAuth auth;
  late AuthRemoteDataSourceImpl dataSource;

  setUpAll(() => registerFallbackValue(_FakeAuthProvider()));

  setUp(() {
    auth = _MockFirebaseAuth();
    dataSource = AuthRemoteDataSourceImpl(auth);
  });

  test('signInWithGoogle dispara o fluxo de redirect', () async {
    when(() => auth.signInWithRedirect(any())).thenAnswer((_) async {});

    await dataSource.signInWithGoogle();

    verify(() => auth.signInWithRedirect(any())).called(1);
  });

  test('mapeia FirebaseAuthException de rede para NetworkException', () {
    when(() => auth.signInWithRedirect(any()))
        .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

    expect(
      () => dataSource.signInWithGoogle(),
      throwsA(isA<NetworkException>()),
    );
  });

  test('mapeia FirebaseAuthException desconhecida para AuthException', () {
    when(() => auth.signInWithRedirect(any()))
        .thenThrow(FirebaseAuthException(code: 'internal-error'));

    expect(
      () => dataSource.signInWithGoogle(),
      throwsA(isA<AuthException>()),
    );
  });
}
