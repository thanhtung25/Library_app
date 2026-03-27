import 'package:library_app/model/book_model.dart';

abstract class BookState {}

// ─── BASE ────────────────────────────────────────────────────────────────────

class BookInitial extends BookState {}

class BookLoading extends BookState {}

class BookError extends BookState {
  final String message;
  BookError(this.message);
}

// ─── READ ────────────────────────────────────────────────────────────────────

class BookSuccess extends BookState {
  final List<BookModel> books;
  BookSuccess(this.books);
}

class BookByCategorySuccess extends BookState {
  final Map<String, List<BookModel>> booksByCategory;
  final List<BookModel> allBooks;
  BookByCategorySuccess(this.booksByCategory, this.allBooks);
}

class BookByIdSucces extends BookState {
  final BookModel bookModel;
  BookByIdSucces({required this.bookModel});
}

class AuthorLoadedState extends BookState {
  final AuthorModel author;
  AuthorLoadedState({required this.author});
}

// ─── CREATE ──────────────────────────────────────────────────────────────────

class BookCreatedSuccess extends BookState {
  final BookModel book;
  BookCreatedSuccess({required this.book});
}

// ─── UPDATE ──────────────────────────────────────────────────────────────────

class BookUpdatedSuccess extends BookState {
  final BookModel book;
  BookUpdatedSuccess({required this.book});
}

// ─── DELETE ──────────────────────────────────────────────────────────────────

class BookDeletedSuccess extends BookState {
  final int id_book;
  BookDeletedSuccess({required this.id_book});
}