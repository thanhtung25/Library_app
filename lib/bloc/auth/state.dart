import '../../model/user_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserModel user;
  AuthSuccess(this.user);
}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}

class UserUpdateSuccess extends AuthState {
  final UserModel user;
  UserUpdateSuccess(this.user);
}
class UploadAvatarLoading extends AuthState {}
class AvatarUploadSuccess extends AuthState {
  final UserModel user;
  AvatarUploadSuccess(this.user);
}