import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/auth/data/models/user_model.dart';
import 'package:pocketbase/pocketbase.dart';

void main() {
  test('should map record fields to model', () {
    final model = UserModel.fromRecord(
      RecordModel.fromJson({
        'id': 'u1',
        'email': 'a@b.com',
        'name': 'Ana',
        'avatar': 'x.png',
      }),
    );
    expect(model.uid, 'u1');
    expect(model.email, 'a@b.com');
    expect(model.displayName, 'Ana');
    expect(model.photoUrl, isNull);
  });

  test('should map missing email to empty string and empty name to null', () {
    final model = UserModel.fromRecord(
      RecordModel.fromJson({'id': 'u1', 'name': ''}),
    );
    expect(model.email, '');
    expect(model.displayName, isNull);
    expect(model.photoUrl, isNull);
  });
}
