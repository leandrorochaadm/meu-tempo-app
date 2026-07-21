import 'package:flutter/material.dart';

import '../pages/edit_task_args.dart';

/// Sentinela devolvida pelo seletor para "tornar a tarefa mãe (raiz)".
const String kMakeRootSentinel = '__root__';

/// Diálogo de seleção de tarefa mãe, reusado pelo "Mover" e pela edição. Cada
/// candidato exibe seu breadcrumb (ancestrais + nível) para desambiguar títulos
/// iguais. Devolve o id escolhido, [kMakeRootSentinel] para raiz, ou `null` se
/// cancelado.
Future<String?> showTaskParentPicker(
  BuildContext context,
  List<ParentCandidate> candidates,
) {
  return showDialog<String?>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Tarefa mãe'),
      children: [
        ListTile(
          leading: const Icon(Icons.home_rounded),
          title: const Text('Tornar tarefa mãe (raiz)'),
          onTap: () => Navigator.of(ctx).pop(kMakeRootSentinel),
        ),
        for (final c in candidates)
          ListTile(
            title: Text(c.title),
            subtitle: Text(c.path),
            onTap: () => Navigator.of(ctx).pop(c.id),
          ),
        ListTile(
          title: const Text('Cancelar'),
          onTap: () => Navigator.of(ctx).pop(),
        ),
      ],
    ),
  );
}
