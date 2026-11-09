import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/core/constants/preferences_keys.dart';
import 'package:meu_tempo/features/auth/data/datasources/account_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('should remove task list filter', () async {
    SharedPreferences.setMockInitialValues({
      PreferencesKeys.taskListFilter: 'lista-7',
    });
    final prefs = await SharedPreferences.getInstance();

    await AccountLocalDataSourceImpl(prefs).clear();

    expect(prefs.containsKey(PreferencesKeys.taskListFilter), isFalse);
  });
}
