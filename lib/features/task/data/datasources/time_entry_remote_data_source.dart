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
}
