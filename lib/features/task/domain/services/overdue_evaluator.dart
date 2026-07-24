import '../entities/task_entity.dart';

/// Regra de "atrasado": **folha não concluída** com prazo estritamente **antes
/// de hoje**. Depende de `today` (dado externo), por isso vive no domínio como
/// serviço — não como getter intrínseco da Entity (ver `architecture.md`).
class OverdueEvaluator {
  const OverdueEvaluator._();

  static bool isOverdue(TaskEntity task, DateTime today) {
    if (task.hasChildren || task.isDone || task.dueDate == null) return false;
    final t0 = DateTime(today.year, today.month, today.day);
    final due =
        DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    return due.isBefore(t0);
  }
}
