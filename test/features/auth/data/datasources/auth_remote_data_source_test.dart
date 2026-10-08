import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/error/exceptions.dart';
import 'package:meu_tempo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _FakeAuthProvider extends Fake implements AuthProvider {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockFirebaseApp extends Mock implements FirebaseApp {}

void main() {
  late _MockFirebaseAuth auth;

  setUpAll(() => registerFallbackValue(_FakeAuthProvider()));

  /// Em teste a página roda em origem de arquivo local, então `Uri.base.host`
  /// nunca bate com um `authDomain` remoto — o fluxo exercitado é o popup.
  /// Passando `Uri.base.host` como authDomain, exercitamos o redirect.
  void stubAuthDomain(String? domain) {
    final app = _MockFirebaseApp();
    when(() => app.options).thenReturn(
      FirebaseOptions(
        apiKey: 'k',
        appId: 'a',
        messagingSenderId: 's',
        projectId: 'p',
        authDomain: domain,
      ),
    );
    when(() => auth.app).thenReturn(app);
  }

  setUp(() {
    auth = _MockFirebaseAuth();
    stubAuthDomain('outro-dominio.example');
  });

  group('web', () {
    late AuthRemoteDataSourceImpl dataSource;

    setUp(() => dataSource = AuthRemoteDataSourceImpl(auth, isWeb: true));

    test('usa redirect quando o app roda no mesmo domínio do authDomain',
        () async {
      stubAuthDomain(Uri.base.host);
      when(() => auth.signInWithRedirect(any())).thenAnswer((_) async {});

      await dataSource.signInWithGoogle();

      verify(() => auth.signInWithRedirect(any())).called(1);
      verifyNever(() => auth.signInWithPopup(any()));
    });

    test('usa popup quando a origem difere do authDomain', () async {
      when(() => auth.signInWithPopup(any()))
          .thenAnswer((_) async => _MockUserCredential());

      await dataSource.signInWithGoogle();

      verify(() => auth.signInWithPopup(any())).called(1);
    });

    test('mapeia popup fechado pelo usuário para SignInCancelledException',
        () {
      when(() => auth.signInWithPopup(any()))
          .thenThrow(FirebaseAuthException(code: 'popup-closed-by-user'));

      expect(
        () => dataSource.signInWithGoogle(),
        throwsA(isA<SignInCancelledException>()),
      );
    });

    test('mapeia FirebaseAuthException de rede para NetworkException', () {
      when(() => auth.signInWithPopup(any()))
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      expect(
        () => dataSource.signInWithGoogle(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('mapeia FirebaseAuthException desconhecida para AuthException', () {
      when(() => auth.signInWithPopup(any()))
          .thenThrow(FirebaseAuthException(code: 'internal-error'));

      expect(
        () => dataSource.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('nativo', () {
    late AuthRemoteDataSourceImpl nativeDataSource;

    setUp(
      () => nativeDataSource = AuthRemoteDataSourceImpl(auth, isWeb: false),
    );

    test('usa signInWithProvider e nunca redirect nem popup', () async {
      when(() => auth.signInWithProvider(any()))
          .thenAnswer((_) async => _MockUserCredential());

      await nativeDataSource.signInWithGoogle();

      verify(() => auth.signInWithProvider(any())).called(1);
      verifyNever(() => auth.signInWithRedirect(any()));
      verifyNever(() => auth.signInWithPopup(any()));
    });

    for (final code in ['web-context-canceled', 'web-context-cancelled']) {
      test('mapeia $code (aba do Google fechada) para SignInCancelledException',
          () {
        when(() => auth.signInWithProvider(any()))
            .thenThrow(FirebaseAuthException(code: code));

        expect(
          () => nativeDataSource.signInWithGoogle(),
          throwsA(isA<SignInCancelledException>()),
        );
      });
    }

    for (final code in ['network-request-failed', 'web-network-request-failed']) {
      test('mapeia $code (sem rede) para NetworkException', () {
        when(() => auth.signInWithProvider(any()))
            .thenThrow(FirebaseAuthException(code: code));

        expect(
          () => nativeDataSource.signInWithGoogle(),
          throwsA(isA<NetworkException>()),
        );
      });
    }
  });
}
