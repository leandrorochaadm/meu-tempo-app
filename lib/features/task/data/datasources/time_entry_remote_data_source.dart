import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../models/time_entry_model.dart';
import '../time_entry_fields.dart';

abstract class TimeEntryRemoteDataSource {
  Future<void> add(TimeEntryModel entry);
  Stream<List<TimeEntryModel>> watchBetween(DateTime start, DateTime end);
  Stream<List<TimeEntryModel>> watchByTarget(String targetId);
  Future<void> update(TimeEntryModel entry);
  Future<void> delete(String id);
}

@LazySingleton(as: TimeEntryRemoteDataSource)
class TimeEntryRemoteDataSourceImpl implements TimeEntryRemoteDataSource {
  TimeEntryRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const UnauthenticatedException();
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.timeEntries(_uid));

  @override
  Future<void> add(TimeEntryModel entry) async {
    try {
      await _collection.add(entry.toJson());
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Stream<List<TimeEntryModel>> watchBetween(DateTime start, DateTime end) {
    try {
      return _collection
          .where(TimeEntryFields.occurredAt,
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where(TimeEntryFields.occurredAt,
              isLessThan: Timestamp.fromDate(end))
          .orderBy(TimeEntryFields.occurredAt)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => TimeEntryModel.fromDoc(d.id, d.data()))
              .toList());
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Stream<List<TimeEntryModel>> watchByTarget(String targetId) {
    try {
      // Sem `orderBy` na query: ordena em memória (mais recentes primeiro) para
      // não exigir índice composto `targetId` + `occurredAt` (volume baixo).
      return _collection
          .where(TimeEntryFields.targetId, isEqualTo: targetId)
          .snapshots()
          .map((snap) {
        final models = snap.docs
            .map((d) => TimeEntryModel.fromDoc(d.id, d.data()))
            .toList()
          ..sort((a, b) {
            final da = a.occurredAt;
            final db = b.occurredAt;
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });
        return models;
      });
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> update(TimeEntryModel entry) async {
    try {
      await _collection.doc(entry.id).set(entry.toJson());
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
