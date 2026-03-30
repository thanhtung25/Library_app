import 'package:bloc/bloc.dart';
import 'package:library_app/api_localhost/BookService.dart';

import '../../model/book_model.dart';
import 'event.dart';
import 'state.dart';

class BookBloc extends Bloc<BookEvent, BookState> {
  final bookService bookservice;
  final Map<String, List<BookModel>> _booksByCategory = {};
  List<BookModel> _allBooks = [];

  BookBloc(this.bookservice) : super(BookInitial()) {
    // ─── READ ──────────────────────────────────────────────────────────────
    on<GetBookEvent>(_getBooks);
    on<GetBookByCategoryEvent>(_getBookByCategory);
    on<GetBookByIdEvent>(_getBookById);

    // ─── CREATE / UPDATE / DELETE ──────────────────────────────────────────
    on<CreateBookEvent>(_createBook);
    on<UpdateBookEvent>(_updateBook);
    on<DeleteBookEvent>(_deleteBook);
    on<UploadImgBookSubmitted>(_onUploadImgBookSubmitted);

  }

  // ─── READ ──────────────────────────────────────────────────────────────────

  Future<void> _getBooks(
      GetBookEvent event,
      Emitter<BookState> emit,
      ) async {
    emit(BookLoading());
    try {
      final books = await bookservice.getAllBook();
      _allBooks = books;
      emit(BookSuccess(books));
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }

  Future<void> _getBookByCategory(
      GetBookByCategoryEvent event,
      Emitter<BookState> emit,
      ) async {
    try {
      final books = await bookservice.getBookByCategory(event.category);
      _booksByCategory[event.category] = books;
      emit(BookByCategorySuccess(Map.from(_booksByCategory), _allBooks));
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }

  Future<void> _getBookById(
      GetBookByIdEvent event,
      Emitter<BookState> emit,
      ) async {
    emit(BookLoading());
    try {
      final book = await bookservice.getBookById(event.id_book);
      emit(BookByIdSucces(bookModel: book));
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }




  // ─── CREATE ────────────────────────────────────────────────────────────────

  Future<void> _createBook(
      CreateBookEvent event,
      Emitter<BookState> emit,
      ) async {
    emit(BookLoading());
    try {
      final newBook = await bookservice.createBook(
        id_category: event.id_category,
        id_author: event.id_author,
        title: event.title,
        isbn: event.isbn,
        language: event.language,
        publish_year: event.publish_year,
        description: event.description,
        image_url: event.image_url,
        created_at: event.created_at,
      );
      _allBooks = [..._allBooks, newBook];
      emit(BookCreatedSuccess(book: newBook));
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }

  // ─── UPDATE ────────────────────────────────────────────────────────────────

  Future<void> _updateBook(
      UpdateBookEvent event,
      Emitter<BookState> emit,
      ) async {
    emit(BookLoading());
    try {
      final updatedBook = await bookservice.updateBook(
        id_book: event.id_book,
        id_category: event.id_category,
        id_author: event.id_author,
        title: event.title,
        isbn: event.isbn,
        language: event.language,
        publish_year: event.publish_year,
        description: event.description,
        image_url: event.image_url,
        created_at: event.created_at,
      );
      _allBooks = _allBooks
          .map((b) => b.id_book == event.id_book ? updatedBook : b)
          .toList();
      _booksByCategory.updateAll((category, books) =>
          books.map((b) => b.id_book == event.id_book ? updatedBook : b).toList());
      emit(BookUpdatedSuccess(book: updatedBook));
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }

  Future<void> _onUploadImgBookSubmitted(
      UploadImgBookSubmitted event,
      Emitter<BookState> emit,
      ) async {
    emit(UploadImageLoading());

    try {
      final user = await bookservice.uploadImg(
        id_book: event.id_book,
        imageFile: event.imageFile,
      );

      emit(ImgBookUploadSuccess(user));
    } catch (e) {
      emit(BookError('Upload img failed: $e'));
    }
  }

  // ─── DELETE ────────────────────────────────────────────────────────────────

  Future<void> _deleteBook(
      DeleteBookEvent event,
      Emitter<BookState> emit,
      ) async {
    emit(BookLoading());
    try {
      await bookservice.deleteBook(event.id_book);
      _allBooks = _allBooks.where((b) => b.id_book != event.id_book).toList();
      _booksByCategory.updateAll((category, books) =>
          books.where((b) => b.id_book != event.id_book).toList());
      emit(BookDeletedSuccess(id_book: event.id_book));
    } catch (e) {
      emit(BookError(e.toString()));
    }
  }
}