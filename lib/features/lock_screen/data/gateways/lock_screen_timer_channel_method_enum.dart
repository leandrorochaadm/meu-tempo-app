/// Methods of the lock screen timer channel (Dart → native).
enum LockScreenTimerChannelMethodEnum {
  show('show'),
  clear('clear'),
  getPermissionStatus('getPermissionStatus'),
  requestPermission('requestPermission'),
  openNotificationSettings('openNotificationSettings');

  const LockScreenTimerChannelMethodEnum(this.apiValue);

  final String apiValue;
}
