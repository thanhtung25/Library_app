import '../../model/book_model.dart';

abstract class BookEvent {}

// ─── READ ────────────────────────────────────────────────────────────────────

class GetBookEvent extends BookEvent {}

class GetBookByCategoryEvent extends BookEvent {
  final String category;
  GetBookByCategoryEvent({required this.category});
}

class GetBookByIdEvent extends BookEvent {
  final int id_book;
  GetBookByIdEvent({required this.id_book});
}

class GetAuthorByIdBookEvent extends BookEvent {
  final int id_book;
  GetAuthorByIdBookEvent({required this.id_book});
}

// ─── CREATE ──────────────────────────────────────────────────────────────────


class CreateBookEvent extends BookEvent {
  final int id_category;
  final int id_author;
  final String title;
  final String isbn;
  final String language;
  final int publish_year;
  final String description;
  final String image_url;
  final DateTime? created_at;

  CreateBookEvent({
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
}
// ─── UPDATE ──────────────────────────────────────────────────────────────────

class UpdateBookEvent extends BookEvent {
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

  UpdateBookEvent({
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
}
// ─── DELETE ──────────────────────────────────────────────────────────────────

class DeleteBookEvent extends BookEvent {
  final int id_book;
  DeleteBookEvent({required this.id_book});
}