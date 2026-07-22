import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/preferences_keys.dart';
import 'package:meu_tempo/features/task/data/datasources/task_list_filter_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late TaskListFilterLocalDataSourceImpl dataSource;

  Future<void> initWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    prefs = await SharedPreferences.getInstance();
    dataSource = TaskListFilterLocalDataSourceImpl(prefs);
  }

  test('getSelectedListId retorna null quando a chave não existe', () async {
    await initWith({});
    expect(dataSource.getSelectedListId(), isNull);
  });

  test('getSelectedListId lê o valor salvo', () async {
    await initWith({PreferencesKeys.taskListFilter: 'lista-42'});
    expect(dataSource.getSelectedListId(), 'lista-42');
  });

  test('setSelectedListId grava o valor', () async {
    await initWith({});
    await dataSource.setSelectedListId('lista-7');
    expect(prefs.getString(PreferencesKeys.taskListFilter), 'lista-7');
  });

  test('setSelectedListId(null) remove a chave', () async {
    await initWith({PreferencesKeys.taskListFilter: 'lista-7'});
    await dataSource.setSelectedListId(null);
    expect(prefs.containsKey(PreferencesKeys.taskListFilter), isFalse);
  });
}
