import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/exceptions.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Stream<List<TaskModel>> watchTasks();
  Future<TaskModel> create(TaskModel task);
}

@LazySingleton(as: TaskRemoteDataSource)
class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  TaskRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const UnauthenticatedException();
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.tasks(_uid));

  @override
  Stream<List<TaskModel>> watchTasks() {
    try {
      return _collection.orderBy('createdAt', descending: true).snapshots().map(
            (snap) => snap.docs
                .map((d) => TaskModel.fromDoc(d.id, d.data()))
                .toList(),
          );
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }

  @override
  Future<TaskModel> create(TaskModel task) async {
    try {
      final ref = await _collection.add(task.toJson());
      final doc = await ref.get();
      return TaskModel.fromDoc(doc.id, doc.data()!);
    } on FirebaseException catch (e) {
      throw mapFirestoreException(e);
    }
  }
}
