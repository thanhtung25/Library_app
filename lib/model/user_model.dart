class UserModel {
  final int id_user;
  final String fullName;
  final DateTime? birth_day;
  final String gender;
  final String email;
  final String phone;
  final String username;
  final String password;
  final String status;
  final DateTime? created_at;
  final String library_card;
  final String address;
  final String avatar_url;
  final String role;

  UserModel({
    required this.id_user,
    required this.fullName,
    required this.birth_day,
    required this.gender,
    required this.email,
    required this.phone,
    required this.username,
    required this.password,
    required this.status,
    required this.created_at,
    required this.library_card,
    required this.address,
    required this.avatar_url,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id_user: json['id_user'] ?? 0,
      fullName: json['full_name'] ?? '',
      birth_day: json['birth_day'] != null &&
          json['birth_day'].toString().isNotEmpty
          ? DateTime.tryParse(json['birth_day'].toString())
          : null,
      gender: json['gender'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      status: json['status'] ?? '',
      created_at: json['created_at'] != null &&
          json['created_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      library_card: json['library_card'] ?? '',
      address: json['address'] ?? '',
      avatar_url: json['avatar_url'] ?? '',
      role: json['role'] ?? '',
    );
  }

  UserModel copyWith({
    int? id_user,
    String? fullName,
    DateTime? birth_day,
    String? gender,
    String? email,
    String? phone,
    String? username,
    String? password,
    String? status,
    DateTime? created_at,
    String? library_card,
    String? address,
    String? avatar_url,
    String? role,
  }) {
    return UserModel(
      id_user: id_user ?? this.id_user,
      fullName: fullName ?? this.fullName,
      birth_day: birth_day ?? this.birth_day,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      password: password ?? this.password,
      status: status ?? this.status,
      created_at: created_at ?? this.created_at,
      library_card: library_card ?? this.library_card,
      address: address ?? this.address,
      avatar_url: avatar_url ?? this.avatar_url,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': id_user,
      'full_name': fullName,
      'birth_day': birth_day?.toIso8601String().split('T')[0],
      'gender': gender,
      'email': email,
      'phone': phone,
      'username': username,
      'password': password,
      'status': status,
      'created_at': created_at?.toIso8601String(),
      'library_card': library_card,
      'address': address,
      'avatar_url': avatar_url,
      'role': role,
    };
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final UserModel? user;

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      token: json['token'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}