import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the `shouldSave` argument of every `finishAutofillContext` call.
List<Object?> recordFinishAutofillContext(WidgetTester tester) {
  final args = <Object?>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.textInput, (call) async {
    if (call.method == 'TextInput.finishAutofillContext') {
      args.add(call.arguments);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.textInput, null),
  );
  return args;
}
