/// Caminhos e segmentos de coleção do Firestore, centralizados.
///
/// Proibido espalhar strings de coleção (`'users'`, `'tasks'`) pelo código
/// (ver `.claude/rules/enums.md`). Todo dado é isolado por `uid`.
class FirestorePaths {
  const FirestorePaths._();

  static const String usersSegment = 'users';
  static const String listsSegment = 'lists';
  static const String tasksSegment = 'tasks';
  static const String appointmentsSegment = 'appointments';
  static const String timeEntriesSegment = 'timeEntries';
  static const String configSegment = 'config';

  static String user(String uid) => '$usersSegment/$uid';
  static String lists(String uid) => '${user(uid)}/$listsSegment';
  static String tasks(String uid) => '${user(uid)}/$tasksSegment';
  static String appointments(String uid) => '${user(uid)}/$appointmentsSegment';
  static String timeEntries(String uid) => '${user(uid)}/$timeEntriesSegment';
}
