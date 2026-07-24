import 'package:equatable/equatable.dart';

/// Candidato a tarefa mãe ao mover/re-parentar uma tarefa. Carrega os títulos
/// dos ancestrais e o nível para a `presentation` montar o breadcrumb legível
/// (ex.: "Lançar app › Fazer telas · tarefa filha") — a **regra** de quem pode
/// ser mãe (exclui a própria, descendentes e netas) mora no UseCase de domínio;
/// aqui é só o dado estruturado, sem texto de UI.
class ParentCandidateEntity extends Equatable {
  ParentCandidateEntity({
    required this.id,
    required this.title,
    required this.level,
    required List<String> ancestorTitles,
  }) : ancestorTitles = List.unmodifiable(ancestorTitles);

  final String id;
  final String title;

  /// 0 = mãe, 1 = filha, 2 = neta (neta nunca é candidata — não aceita filhas).
  final int level;

  /// Títulos dos ancestrais, do mais distante ao mais próximo (vazio se raiz).
  final List<String> ancestorTitles;

  @override
  List<Object?> get props => [id, title, level, ancestorTitles];
}
