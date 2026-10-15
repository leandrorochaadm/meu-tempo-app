import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/timestamp_converter.dart';
import '../models/recurring_task_model.dart';
import '../recurring_task_fields.dart';

abstract class RecurringTaskRemoteDataSource {
  Stream<List<RecurringTaskModel>> watchAll();
  Future<List<RecurringTaskModel>> getAll();
  Future<RecurringTaskModel> create(RecurringTaskModel template);

  /// Não grava `lastGeneratedOn` (posse do [claimGeneration]).
  Future<void> update(RecurringTaskModel template);
  Future<void> delete(String id);
  Future<void> restore(RecurringTaskModel template);
  Future<void> moveToList(String fromListId, String toListId);
  Future<void> deleteByList(String listId);

  /// Numa transação: lê o modelo [id]; se ele existe e [canClaim] aceita o
  /// atual, grava `lastGeneratedOn` = meia-noite local de [day] e devolve
  /// `true`; senão não grava nada e devolve `false`. [canClaim] precisa ser
  /// puro (a transação pode reexecutar).
  Future<bool> claimGeneration(
    String id,
    DateTime day, {
    required bool Function(RecurringTaskModel current) canClaim,
  });
}

@LazySingleton(as: RecurringTaskRemoteDataSource)
class RecurringTaskRemoteDataSourceImpl
    implements RecurringTaskRemoteDataSource {
  RecurringTaskRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const UnauthenticatedException();
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.recurringTasks(_uid));

  @override
  Stream<List<RecurringTaskModel>> watchAll() {
    try {
      return _collection
          .orderBy(RecurringTaskFields.title)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => RecurringTaskModel.fromDoc(d.id, d.data()))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<List<RecurringTaskModel>> getAll() async {
    try {
      final snap = await _collection.get();
      return snap.docs
          .map((d) => RecurringTaskModel.fromDoc(d.id, d.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<RecurringTaskModel> create(RecurringTaskModel template) async {
    try {
      final ref = await _collection.add(template.toJson());
      final doc = await ref.get();
      return RecurringTaskModel.fromDoc(doc.id, doc.data()!);
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> update(RecurringTaskModel template) async {
    try {
      // `update` (não `set`): preserva `lastGeneratedOn` e falha com
      // `not-found` se o modelo já foi excluído.
      final data = template.toJson()
        ..remove(RecurringTaskFields.lastGeneratedOn);
      await _collection.doc(template.id).update(data);
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

  @override
  Future<void> restore(RecurringTaskModel template) async {
    try {
      await _collection.doc(template.id).set(template.toJson());
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> moveToList(String fromListId, String toListId) async {
    try {
      final snap = await _collection
          .where(RecurringTaskFields.listId, isEqualTo: fromListId)
          .get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {RecurringTaskFields.listId: toListId});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<void> deleteByList(String listId) async {
    try {
      final snap = await _collection
          .where(RecurringTaskFields.listId, isEqualTo: listId)
          .get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<bool> claimGeneration(
    String id,
    DateTime day, {
    required bool Function(RecurringTaskModel current) canClaim,
  }) async {
    try {
      // Transação: lê e marca o dia de forma atômica. Se dois aparelhos
      // concorrem, o Firestore serializa — o segundo reexecuta, o predicado
      // recusa o dia já gravado e nada é gravado de novo (R3).
      final midnight = DateTime(day.year, day.month, day.day);
      final ref = _collection.doc(id);
      return await _firestore.runTransaction<bool>((txn) async {
        final snap = await txn.get(ref);
        final data = snap.data();
        if (data == null) return false; // modelo excluído: não gera
        if (!canClaim(RecurringTaskModel.fromDoc(snap.id, data))) return false;
        txn.update(ref, {
          RecurringTaskFields.lastGeneratedOn: const TimestampConverter()
              .toJson(midnight),
        });
        return true;
      });
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }
}
