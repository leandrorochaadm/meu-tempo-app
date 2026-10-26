import 'package:pocketbase/pocketbase.dart';

import '../../../../core/constants/pb_schema.dart';
import '../../domain/entities/user_entity.dart';

/// Bridge between the PocketBase `users` record and the domain [UserEntity].
/// Does not extend Entity.
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

  /// `photoUrl` stays null: the PocketBase `avatar` is a file and the app
  /// shows no photo.
  factory UserModel.fromRecord(RecordModel record) {
    final name = record.getStringValue(PbFields.name);
    return UserModel(
      uid: record.id,
      email: record.getStringValue(PbFields.email),
      displayName: name.isEmpty ? null : name,
    );
  }

  UserEntity toEntity() => UserEntity(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
}
