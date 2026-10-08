import 'package:flutter_test/flutter_test.dart';
import 'package:meu_tempo/features/appointment/domain/entities/appointment_entity.dart';

void main() {
  AppointmentEntity build({bool? isDone}) => AppointmentEntity(
        id: 'a1',
        title: 'Dentista',
        listId: 'pessoal',
        date: DateTime(2026, 10, 7),
        startMinute: 900,
        durationMinutes: 60,
        isDone: isDone ?? false,
      );

  test('isDone é false por padrão', () {
    final entity = AppointmentEntity(
      id: 'a1',
      title: 'Dentista',
      listId: 'pessoal',
      date: DateTime(2026, 10, 7),
      startMinute: 900,
      durationMinutes: 60,
    );

    expect(entity.isDone, isFalse);
  });

  test('isDone entra na igualdade', () {
    expect(build(isDone: true), isNot(equals(build(isDone: false))));
    expect(build(isDone: true), equals(build(isDone: true)));
  });
}
