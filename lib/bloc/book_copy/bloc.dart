import 'package:bloc/bloc.dart';
import 'package:library_app/api_localhost/BookCopyService.dart';
import 'package:library_app/model/book_copy_model.dart';

import 'event.dart';
import 'state.dart';

class BookCopyBloc extends Bloc<BookCopyEvent, BookCopyState> {
  final BookCopyService bookCopyService;
  final Map<int, List<BookCopyModel>> _booksByIdBook = {};
  List<BookCopyModel> _allBookCopy = [];
  BookCopyBloc(this.bookCopyService) : super(BookCopyInitial()) {
    on<GetBookCopyEvent>(_getBookCopy);
    on<GetBookByIdBookEvent>(_getBookByIdBook);
  }

  Future<void> _getBookCopy(
      GetBookCopyEvent event,
      Emitter<BookCopyState> emit,
      )async{
    emit(BookCopyLoading());
    try{
      final bookCopy = await bookCopyService.getAllBookCopies();
      _allBookCopy = bookCopy;
      emit(BookCopySuccess(
          bookCopy));
    }catch(e){
      emit(BookCopyError(e.toString()));
    }
  }
  Future<void> _getBookByIdBook(
      GetBookByIdBookEvent event,
      Emitter<BookCopyState> emit,
      ) async {
    // Không emit Loading để tránh reset toàn bộ UI khi lazy-load từng cuốn
    try {
      // API trả về một BookCopyModel đơn lẻ → bọc vào List
      final List<BookCopyModel> copies =
      await bookCopyService.getBookCopyByIdBook(event.id_book);

      _booksByIdBook[event.id_book] = copies;

      emit(BookCopyByIdBookSuccess(
        Map.from(_booksByIdBook),
        _allBookCopy,
      ));
    } catch (e) {
      emit(BookCopyError(e.toString()));
    }
  }
  }
