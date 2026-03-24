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
    on<GetBookEvent>(_getBooks);
    on<GetBookByCategoryEvent>(_getBookByCategory);
    on<GetBookByIdEvent>(_getBookById);
  }

  Future<void> _getBooks(
      GetBookEvent event,
      Emitter<BookState> emit,
      )async{
    emit(BookLoading());
    try{
      final books = await bookservice.getAllBook();
      _allBooks = books;
      emit(BookSuccess(
        books));
    }catch(e){
      emit(BookError(e.toString()));
    }
  }

  Future<void> _getBookByCategory(
      GetBookByCategoryEvent event,
      Emitter<BookState> emit,
      )async{
    try{
      final books = await bookservice.getBookByCategory(event.category);
      _booksByCategory[event.category] = books;
      emit(BookByCategorySuccess(
          Map.from(_booksByCategory), _allBooks,));
    }catch(e){
      emit(BookError(e.toString()));
    }
  }

    Future<void> _getBookById(
        GetBookByIdEvent event,
        Emitter<BookState> emit,
        )async{
    emit(BookLoading());
    try{
        final book = await bookservice.getBookById(event.id_book);
        emit(BookByIdSucces(bookModel: book));
    }catch(e){
        emit(BookError(e.toString()));
    }
  }


}
