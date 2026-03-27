import '../model/user_model.dart';
import 'ApiService.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

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

  Future<UserModel> updateUserbyId({
    required int id_user,
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
    final data = await ApiService.put(
      "/users-management/user/$id_user",
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

  Future<UserModel> uploadAvatar({
    required int idUser,
    required File imageFile,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/users-management/user/$idUser/avatar',
    );

    final request = http.MultipartRequest('PUT', uri);

    final mimeType = lookupMimeType(imageFile.path)?.split('/');
    final mediaType = mimeType != null && mimeType.length == 2
        ? MediaType(mimeType[0], mimeType[1])
        : MediaType('image', 'jpeg');

    request.files.add(
      await http.MultipartFile.fromPath(
        'avatar',
        imageFile.path,
        contentType: mediaType,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Upload avatar thất bại: ${response.statusCode}\n${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    if (data['user'] == null) {
      throw Exception('Server không trả về user sau khi upload avatar');
    }

    return UserModel.fromJson(data['user']);
  }
}