#!/usr/bin/env python3
"""PreToolUse hook — Regra Crítica do Meu Tempo.

Bloqueia Write/Edit que introduza regra de negócio (agregação/cálculo numérico)
em arquivos da camada `presentation`. Regra de negócio pertence a `domain`
(Entity ou UseCase). Ver CLAUDE.md > Regra Crítica e .claude/rules/architecture.md.

Contrato do hook: recebe JSON do tool call em stdin. Para bloquear, escreve o
motivo em stderr e sai com código 2 (Claude recebe a mensagem e não executa o tool).
"""
import json
import re
import sys

# Só vale para a camada presentation.
PRESENTATION_RE = re.compile(r"lib/features/[^/]+/presentation/")

# Padrões que denunciam regra de negócio na camada errada.
# Rede de segurança — a defesa primária é de design (o dado chega pronto na UI,
# via getter na Entity ou resultado de UseCase). Cobertura textual, não semântica.
FORBIDDEN = [
    (re.compile(r"\.fold\s*<\s*(int|double|num)\s*>"),
     "agregação numérica com fold<num>"),
    (re.compile(r"\.reduce\s*\("),
     "redução de coleção com reduce()"),
    (re.compile(r"\.sum\b"),
     "soma com .sum (package:collection)"),
    (re.compile(r"\.average\b"),
     "média com .average (package:collection)"),
    (re.compile(r"\+=\s*[\w.]+\.\w+"),
     "acúmulo manual (ex.: total += item.campo)"),
    (re.compile(r"\.(importancia|prioridade|nivel|urgencia)\s*[!=]="),
     "decisão de negócio (ex.: tarefa.importancia == 1) — pertence a Entity/UseCase"),
]

# Escape hatch: linha com este comentário é ignorada (uso deliberado e justificado).
IGNORE_MARK = "// ignore: business-logic"


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0  # sem payload válido → não interfere

    tool = payload.get("tool_name", "")
    if tool not in ("Write", "Edit", "MultiEdit"):
        return 0

    tool_input = payload.get("tool_input", {}) or {}
    file_path = tool_input.get("file_path", "")
    if not PRESENTATION_RE.search(file_path):
        return 0  # fora da presentation → não interfere

    # Reúne o texto que está sendo escrito, conforme o tipo de tool.
    texts = []
    if "content" in tool_input:                 # Write
        texts.append(tool_input["content"])
    if "new_string" in tool_input:              # Edit
        texts.append(tool_input["new_string"])
    for edit in tool_input.get("edits", []):    # MultiEdit
        if isinstance(edit, dict) and "new_string" in edit:
            texts.append(edit["new_string"])

    violations = []
    for text in texts:
        for line in text.splitlines():
            if IGNORE_MARK in line:
                continue
            for regex, reason in FORBIDDEN:
                if regex.search(line):
                    violations.append(f"  • {reason}: {line.strip()}")

    if violations:
        sys.stderr.write(
            "BLOQUEADO — regra de negócio na camada presentation.\n"
            f"Arquivo: {file_path}\n"
            + "\n".join(violations)
            + "\n\nRegra de negócio DEVE morar em `domain`: mova o cálculo/decisão "
            "para um getter na Entity ou para um UseCase. Se o uso for legítimo "
            "(não é regra de negócio), adicione o comentário "
            f"`{IGNORE_MARK}` na linha.\n"
        )
        return 2  # bloqueia o tool

    return 0


if __name__ == "__main__":
    sys.exit(main())
