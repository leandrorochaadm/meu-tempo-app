/// Chaves dos campos do doc do cronômetro ativo no Firestore (sem string solta).
class ActiveTimerFields {
  const ActiveTimerFields._();

  static const String targetId = 'targetId';
  static const String targetType = 'targetType';
  static const String listId = 'listId';
  static const String startedAt = 'startedAt';
  static const String status = 'status';
}
