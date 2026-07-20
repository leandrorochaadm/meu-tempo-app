import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_entity.dart';

/// Ponte entre o `User` do Firebase e a [UserEntity] do domínio.
/// Não estende Entity.
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  factory UserModel.fromFirebaseUser(User user) => UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );

  UserEntity toEntity() => UserEntity(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
}
