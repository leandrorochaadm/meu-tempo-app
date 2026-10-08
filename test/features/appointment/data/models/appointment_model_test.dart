import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/appointment/data/appointment_fields.dart';
import 'package:meu_tempo/features/appointment/data/models/appointment_model.dart';
import 'package:meu_tempo/features/appointment/domain/entities/appointment_entity.dart';

void main() {
  Map<String, dynamic> doc({bool? isDone}) => <String, dynamic>{
        'title': 'Dentista',
        'listId': 'pessoal',
        'date': Timestamp.fromDate(DateTime(2026, 10, 7)),
        'startMinute': 900,
        'durationMinutes': 60,
        'spentMinutes': 15,
        AppointmentFields.isDone: ?isDone,
      };

  test('doc antigo sem isDone é lido como não concluído', () {
    expect(AppointmentModel.fromDoc('a1', doc()).toEntity().isDone, isFalse);
  });

  test('lê isDone true do documento', () {
    final entity = AppointmentModel.fromDoc('a1', doc(isDone: true)).toEntity();

    expect(entity.isDone, isTrue);
  });

  test('toJson grava isDone pela chave de AppointmentFields', () {
    final json = AppointmentModel(
      id: 'a1',
      title: 'Dentista',
      listId: 'pessoal',
      date: DateTime(2026, 10, 7),
      startMinute: 900,
      durationMinutes: 60,
      isDone: true,
    ).toJson();

    expect(json[AppointmentFields.isDone], isTrue);
    expect(json.containsKey('id'), isFalse);
  });

  test('fromEntity → toEntity preserva isDone', () {
    final entity = AppointmentEntity(
      id: 'a1',
      title: 'Dentista',
      listId: 'pessoal',
      date: DateTime(2026, 10, 7),
      startMinute: 900,
      durationMinutes: 60,
      isDone: true,
    );

    expect(AppointmentModel.fromEntity(entity).toEntity(), equals(entity));
  });
}
