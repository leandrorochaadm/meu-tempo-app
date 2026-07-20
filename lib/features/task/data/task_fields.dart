/// Chaves dos campos do documento de tarefa no Firestore (sem string solta em query).
class TaskFields {
  const TaskFields._();

  static const String createdAt = 'createdAt';
  static const String hasChildren = 'hasChildren';
  static const String isDone = 'isDone';
  static const String parentId = 'parentId';
  static const String listId = 'listId';
  static const String spentMinutes = 'spentMinutes';
}
