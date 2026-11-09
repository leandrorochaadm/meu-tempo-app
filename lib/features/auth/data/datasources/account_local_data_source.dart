import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/preferences_keys.dart';

/// The user's data stored on this device. Only I/O.
abstract class AccountLocalDataSource {
  /// Removes the user's preferences from the device.
  Future<void> clear();
}

@LazySingleton(as: AccountLocalDataSource)
class AccountLocalDataSourceImpl implements AccountLocalDataSource {
  const AccountLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> clear() async {
    await _prefs.remove(PreferencesKeys.taskListFilter);
  }
}
