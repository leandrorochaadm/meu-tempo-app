import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../models/appointment_model.dart';

abstract class AppointmentRemoteDataSource {
  Stream<List<AppointmentModel>> watchForDay(DateTime day);
  Future<AppointmentModel> create(AppointmentModel a);
  Future<void> delete(String id);
}

@LazySingleton(as: AppointmentRemoteDataSource)
class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  AppointmentRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _dateField = 'date';
  static const String _startField = 'startMinute';

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const UnauthenticatedException();
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.appointments(_uid));

  @override
  Stream<List<AppointmentModel>> watchForDay(DateTime day) {
    try {
      final start = Timestamp.fromDate(day);
      final end = Timestamp.fromDate(day.add(const Duration(days: 1)));
      return _collection
          .where(_dateField, isGreaterThanOrEqualTo: start)
          .where(_dateField, isLessThan: end)
          .orderBy(_dateField)
          .orderBy(_startField)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => AppointmentModel.fromDoc(d.id, d.data()))
              .toList());
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<AppointmentModel> create(AppointmentModel a) async {
    try {
      final ref = await _collection.add(a.toJson());
      final doc = await ref.get();
      return AppointmentModel.fromDoc(doc.id, doc.data()!);
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _collection.doc(id).delete();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }
}
