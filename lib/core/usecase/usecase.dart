import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// Contrato base de todo UseCase: um único método [call] que recebe [Params]
/// e devolve `Either<Failure, Type>`.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Contrato base de UseCase que expõe um `Stream` (ex.: escutar coleções).
abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

/// Ausência de parâmetros para UseCases sem entrada.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
