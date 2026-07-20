import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Trava de arquitetura — Regra Crítica do Meu Tempo.
///
/// A camada `presentation` (Bloc/State/Page/Widget) NUNCA pode conter regra de
/// negócio: nada de agregação numérica, cálculo ou decisão de domínio. Isso
/// pertence a `domain` (Entity ou UseCase). Ver `CLAUDE.md > Regra Crítica` e
/// `.claude/rules/architecture.md`.
///
/// Este teste varre `lib/features/*/presentation/**` e falha se encontrar
/// padrões que denunciam regra de negócio na camada errada.
void main() {
  test('presentation não contém regra de negócio (agregação/cálculo)', () {
    final presentationDirs = _presentationDirs();

    // Sem features ainda → nada a validar (o teste passa e protege o futuro).
    final offenders = <String>[];

    for (final dir in presentationDirs) {
      for (final file in _dartFiles(dir)) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];

          // Permite desativar numa linha específica com justificativa explícita.
          if (line.contains('// ignore: business-logic')) continue;

          for (final pattern in _forbiddenPatterns) {
            if (pattern.regex.hasMatch(line)) {
              final rel = file.path.replaceFirst('${Directory.current.path}/', '');
              offenders.add('$rel:${i + 1} → ${pattern.reason}\n    ${line.trim()}');
            }
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Regra de negócio detectada na camada presentation. '
          'Mova o cálculo/decisão para uma Entity (getter) ou UseCase.\n\n'
          '${offenders.join('\n')}',
    );
  });
}

/// Padrões que denunciam regra de negócio (agregação/redução numérica).
///
/// Rede de segurança — a defesa primária é de design: o dado chega PRONTO na
/// UI (getter na Entity / resultado do UseCase), então não sobra o que calcular.
/// Estes padrões pegam os escorregões mais comuns. Cobertura textual, não
/// semântica: casos disfarçados dependem de revisão (ver `.claude/rules/architecture.md`).
final _forbiddenPatterns = <_Pattern>[
  _Pattern(
    RegExp(r'\.fold\s*<\s*(int|double|num)\s*>'),
    'agregação numérica com fold<num> — pertence a Entity/UseCase',
  ),
  _Pattern(
    RegExp(r'\.reduce\s*\('),
    'redução de coleção com reduce() — pertence a Entity/UseCase',
  ),
  _Pattern(
    RegExp(r'\.sum\b'),
    'soma com .sum (package:collection) — pertence a Entity/UseCase',
  ),
  _Pattern(
    RegExp(r'\.average\b'),
    'média com .average (package:collection) — pertence a Entity/UseCase',
  ),
  _Pattern(
    RegExp(r'\+=\s*[\w.]+\.\w+'),
    'acúmulo manual (ex.: total += item.campo) — pertence a Entity/UseCase',
  ),
  _Pattern(
    RegExp(r'\.(importancia|prioridade|nivel|urgencia)\s*[!=]='),
    'decisão de negócio (ex.: tarefa.importancia == 1) — pertence a Entity/UseCase',
  ),
];

class _Pattern {
  final RegExp regex;
  final String reason;
  const _Pattern(this.regex, this.reason);
}

List<Directory> _presentationDirs() {
  final featuresDir = Directory('lib/features');
  if (!featuresDir.existsSync()) return const [];

  return featuresDir
      .listSync()
      .whereType<Directory>()
      .map((f) => Directory('${f.path}/presentation'))
      .where((d) => d.existsSync())
      .toList();
}

Iterable<File> _dartFiles(Directory dir) => dir
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));
