import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';

/// Contrato de I/O do filtro de lista da tela principal — preferência de UI
/// **local no dispositivo** (não é dado de negócio na nuvem). `null` = todas.
abstract class TaskListFilterRepository {
  /// Lê a lista selecionada como filtro (`null` = "Todas as listas").
  Future<Either<Failure, String?>> getSelectedListId();

  /// Grava a lista selecionada (`null` limpa o filtro → "Todas as listas").
  Future<Either<Failure, Unit>> setSelectedListId(String? listId);
}
