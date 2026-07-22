import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/preferences_keys.dart';

/// Acesso local (device) ao filtro de lista da tela principal, via
/// `shared_preferences`. Só I/O — nenhuma regra de negócio.
abstract class TaskListFilterLocalDataSource {
  /// Lista salva (`null` = ausente → "Todas as listas").
  String? getSelectedListId();

  /// Grava a lista (`null` remove a chave).
  Future<void> setSelectedListId(String? listId);
}

@LazySingleton(as: TaskListFilterLocalDataSource)
class TaskListFilterLocalDataSourceImpl
    implements TaskListFilterLocalDataSource {
  const TaskListFilterLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? getSelectedListId() =>
      _prefs.getString(PreferencesKeys.taskListFilter);

  @override
  Future<void> setSelectedListId(String? listId) async {
    if (listId == null) {
      await _prefs.remove(PreferencesKeys.taskListFilter);
    } else {
      await _prefs.setString(PreferencesKeys.taskListFilter, listId);
    }
  }
}
