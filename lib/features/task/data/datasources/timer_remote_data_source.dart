import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../models/active_timer_model.dart';

abstract class TimerRemoteDataSource {
  Stream<ActiveTimerModel?> watchActive();
  Future<ActiveTimerModel?> getActive();
  Future<void> setActive(ActiveTimerModel timer);
  Future<void> clear();
}

@LazySingleton(as: TimerRemoteDataSource)
class TimerRemoteDataSourceImpl implements TimerRemoteDataSource {
  TimerRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const UnauthenticatedException();
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection(FirestorePaths.config(_uid))
      .doc(FirestorePaths.activeTimerDoc);

  ActiveTimerModel? _parse(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) return null;
    return ActiveTimerModel.fromJson(data);
  }

  @override
  Stream<ActiveTimerModel?> watchActive() {
    try {
      return _doc.snapshots().map(_parse);
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<ActiveTimerModel?> getActive() async {
    try {
      return _parse(await _doc.get());
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> setActive(ActiveTimerModel timer) async {
    try {
      await _doc.set(timer.toJson());
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _doc.delete();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }
}
