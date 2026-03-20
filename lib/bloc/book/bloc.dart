import 'package:bloc/bloc.dart';
import 'package:library_app/api_localhost/bookService.dart';

import 'event.dart';
import 'state.dart';

class BookBloc extends Bloc<BookEvent, BookState> {
  final bookService bookservice;
  BookBloc(this.bookservice) : super(BookInitial()) {
    on<GetBookEvent>(_getBooks);
  }

  Future<void> _getBooks(
      GetBookEvent event,
      Emitter<BookState> emit,
      )async{
    emit(BookLoading());
    try{
      final books = await bookservice.getAllBook();
      emit(BookSuccess(books));
    }catch(e){
      emit(BookError(e.toString()));
    }
  }
}
