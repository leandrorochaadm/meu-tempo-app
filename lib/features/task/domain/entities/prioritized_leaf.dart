import 'package:equatable/equatable.dart';

import 'task_entity.dart';

/// Folha na listagem por prioridade, com a pontuação calculada e o subtítulo
/// da hierarquia (mãe › avó).
class PrioritizedLeaf extends Equatable {
  const PrioritizedLeaf({
    required this.task,
    required this.priority,
    required this.ancestryLabel,
  });

  final TaskEntity task;
  final int priority;

  /// Ex.: "Lançar app › Fazer telas" (vazio se a folha for raiz).
  final String ancestryLabel;

  @override
  List<Object?> get props => [task, priority, ancestryLabel];
}
