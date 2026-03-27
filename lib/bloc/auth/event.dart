import 'dart:io';

abstract class AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;

  LoginSubmitted({
    required this.username,
    required this.password,
  });

}

class RegisterSubmitted extends AuthEvent{
  final String fullName;
  final String username;
  final String password;
  final String role;
  final String? email;
  final String gender;
  final String? birthDay;
  final String phone;
  final String status;
  String? createdAt;
  final String libraryCard;
  final String address;
  final String avatarUrl;
  RegisterSubmitted({
    required this.fullName,
    required this.username,
    required this.password,
    required this.role,
    required this.email,
    required this.gender,
    required this.birthDay,
    required this.phone,
    required this.status,
    required this.createdAt,
    required this.libraryCard,
    required this.address,
    required this.avatarUrl,
});
}
class UserUpdateSubmittedEvent extends AuthEvent {
  final int id_user;
  final String fullName;
  final String username;
  final String password;
  final String role;
  final String? email;
  final String gender;
  final String? birthDay;
  final String phone;
  final String status;
  String? createdAt;
  final String libraryCard;
  final String address;
  final String avatarUrl;

  UserUpdateSubmittedEvent({
    required this.id_user,
    required this.fullName,
    required this.username,
    required this.password,
    required this.role,
    required this.email,
    required this.gender,
    required this.birthDay,
    required this.phone,
    required this.status,
    required this.createdAt,
    required this.libraryCard,
    required this.address,
    required this.avatarUrl,
  });
}

class UploadAvatarSubmitted extends AuthEvent {
  final int id_user;
  final File imageFile;

  UploadAvatarSubmitted({
    required this.id_user,
    required this.imageFile,
  });
}