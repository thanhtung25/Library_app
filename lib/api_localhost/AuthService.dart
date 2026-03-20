import '../model/user_model.dart';
import 'ApiService.dart';

class AuthService {
  Future<LoginResponse> login(
      String username,
      String password,
      ) async {
    final data = await ApiService.post(
      "/login",
      {
        "username": username,
        "password": password,
      },
    );

    return LoginResponse.fromJson(data);
  }

  Future<UserModel> register({
    required String fullName,
    required String username,
    required String password,
    required String role,
    required String? email,
    required String gender,
    required String? birthDay,
    required String phone,
    required String status,
    String? createdAt,
    required String libraryCard,
    required String address,
    required String avatarUrl,
  }) async {
    final data = await ApiService.post(
      '/users-management/user',
      {
        'full_name': fullName,
        'username': username,
        'password': password,
        'role': role,
        'email': email,
        'gender': gender,
        'birth_day': birthDay,
        'phone': phone,
        'status': status,
        'created_at': createdAt,
        'library_card': libraryCard,
        'address': address,
        'avatar_url': avatarUrl,
      },
    );

    return UserModel.fromJson(data);
  }

  Future<UserModel> getUserbyId(
      int id_user
      )async {
    final data = await ApiService.get(
      "/users-management/user/${id_user}",
    );
    return UserModel.fromJson(data);
  }
}