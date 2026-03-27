
import '../../model/book_copy_model.dart';

abstract class BookCopyState {}

class BookCopyInitial extends BookCopyState {}

class BookCopyLoading extends BookCopyState {}

class BookCopySuccess extends BookCopyState {
  final List<BookCopyModel> bookCopies;
  BookCopySuccess(this.bookCopies);
}

class BookCopyError extends BookCopyState {
  final String message;
  BookCopyError(this.message);
}

class BookCopyByIdBookSuccess extends BookCopyState {
  final Map<int, List<BookCopyModel>> bookCopybyIdBook;
  final List<BookCopyModel> bookCopies;
  BookCopyByIdBookSuccess(this.bookCopybyIdBook, this.bookCopies,);
}

class BookCopyUpdatedSuccess extends BookCopyState {
  final BookCopyModel bookCopy;
  BookCopyUpdatedSuccess({required this.bookCopy});
}
