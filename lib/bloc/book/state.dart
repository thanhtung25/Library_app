


import 'package:library_app/model/book_model.dart';

abstract class BookState {}

class BookInitial extends BookState {}

class BookLoading extends BookState {}

class BookSuccess extends BookState {
  final List<BookModel> books;
  BookSuccess(this.books);
}

class BookError extends BookState {
  final String message;
  BookError(this.message);
}


class BookByCategorySuccess extends BookState {
  final Map<String, List<BookModel>> booksByCategory;
  final List<BookModel> allBooks;
  BookByCategorySuccess(this.booksByCategory, this.allBooks,);
}

class BookByIdSucces extends BookState{
  final BookModel bookModel;
  BookByIdSucces({required this.bookModel});
}
