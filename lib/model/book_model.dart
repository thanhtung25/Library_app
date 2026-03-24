import 'package:flutter/cupertino.dart';

class BookModel {
  final int id_book;
  final int id_category;
  final int id_author;
  final String title;
  final String isbn;
  final String language;
  final int publish_year;
  final String description;
  final String image_url;
  final DateTime? created_at;

  BookModel({
    required this.id_book,
    required this.id_category,
    required this.id_author,
    required this.title,
    required this.isbn,
    required this.language,
    required this.publish_year,
    required this.description,
    required this.image_url,
    required this.created_at,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id_book: json['id_book'] ?? 0,
      id_category: json['id_category'] ?? 0,
      id_author: json['id_author'] ?? 0,
      title: json['title'] ?? '',
      isbn: json['isbn'] ?? '',
      language: json['language'] ?? '',
      publish_year: json['publish_year'] ?? 0,
      description: json['description'] ?? '',
      image_url: json['image_url'] ?? '',
      created_at: json['created_at'] != null &&
          json['created_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_book': id_book,
      'id_category': id_category,
      'id_author': id_author,
      'title': title,
      'isbn': isbn,
      'language': language,
      'publish_year': publish_year,
      'description': description,
      'image_url': image_url,
      'created_at': created_at?.toIso8601String(),
    };
  }
}


class AuthorModel{
  final int id_author;
  final String full_name;
  final String biography;

  AuthorModel({
    required this.id_author,
    required this.full_name,
    required this.biography
  });

  factory AuthorModel.fromJson(Map<String,dynamic> json){
    return AuthorModel(
        id_author: json["id_author"] ?? 0,
        full_name: json["full_name"] ?? "",
        biography: json["biography"] ?? ""
    );
  }

  Map<String, dynamic> toJson(){
    return{
      'id_author' : id_author,
      'full_name' : full_name,
      'biography' : biography,
    };
}
}

