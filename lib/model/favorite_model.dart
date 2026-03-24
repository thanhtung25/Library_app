class FavoriteModel {
  final int? id_favorite;
  final int id_user;
  final int id_book;
  final DateTime? created_at;

  FavoriteModel({this.id_favorite, required this.id_user, required this.id_book, this.created_at});

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id_favorite: json['id_favorite'],
      id_user: json['id_user'] ?? 0,
      id_book: json['id_book'] ?? 0,
      created_at: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_favorite': id_favorite, 'id_user': id_user,
      'id_book': id_book, 'created_at': created_at?.toIso8601String(),
    };
  }

  FavoriteModel copyWith({int? id_favorite, int? id_user, int? id_book, DateTime? created_at}) {
    return FavoriteModel(
      id_favorite: id_favorite ?? this.id_favorite, id_user: id_user ?? this.id_user,
      id_book: id_book ?? this.id_book, created_at: created_at ?? this.created_at,
    );
  }
}
