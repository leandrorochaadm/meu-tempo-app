import 'package:equatable/equatable.dart';

/// Usuário autenticado. Imutável e pura (sem Firebase, sem `copyWith`).
class UserEntity extends Equatable {
  const UserEntity({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl];
}
