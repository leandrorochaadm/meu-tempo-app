import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../models/day_config_model.dart';

abstract class ConfigRemoteDataSource {
  Stream<DayConfigModel> watchConfig();
  Future<DayConfigModel> getConfig();
  Future<void> setAvailableMinutes(int minutes);
  Future<void> markOnboarded();
}

@LazySingleton(as: ConfigRemoteDataSource)
class ConfigRemoteDataSourceImpl implements ConfigRemoteDataSource {
  ConfigRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _availableField = 'availableMinutesPerDay';
  static const String _onboardedField = 'onboarded';

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const UnauthenticatedException();
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection(FirestorePaths.config(_uid))
      .doc(FirestorePaths.settingsDoc);

  @override
  Stream<DayConfigModel> watchConfig() {
    try {
      return _doc.snapshots().map((snap) {
        final data = snap.data();
        // Sem doc ainda → usa o padrão da model.
        return data == null
            ? const DayConfigModel()
            : DayConfigModel.fromJson(data);
      });
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<DayConfigModel> getConfig() async {
    try {
      final snap = await _doc.get();
      final data = snap.data();
      return data == null
          ? const DayConfigModel()
          : DayConfigModel.fromJson(data);
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> setAvailableMinutes(int minutes) async {
    try {
      await _doc.set({_availableField: minutes}, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> markOnboarded() async {
    try {
      await _doc.set({_onboardedField: true}, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }
}
