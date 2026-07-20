import 'package:equatable/equatable.dart';

/// Lista (categoria) à qual as tarefas pertencem. A "Entrada" é a lista fixa
/// padrão (`isDefault == true`), destino da criação rápida.
class TaskListEntity extends Equatable {
  const TaskListEntity({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final bool isDefault;

  @override
  List<Object?> get props => [id, name, isDefault];
}
