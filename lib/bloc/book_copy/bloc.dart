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
    on<AddBookCopyEvent>(_addBookCopy);
    on<UpdateBookCopyEvent>(_updateBookCopy);

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
  // CREATE
  Future<void> _addBookCopy(
      AddBookCopyEvent event,
      Emitter<BookCopyState> emit,
      ) async {
    emit(BookCopyLoading());
    try {
      final newCopy = BookCopyModel(
        id_book:       event.id_book,
        barcode:       event.barcode,
        qr_code:       event.qr_code,
        location:      event.location,
        received_date: event.received_date,
        condition:     event.condition,
        status:        event.status,
      );
      final result = await bookCopyService.addBookCopy(newCopy);
      _allBookCopy = [..._allBookCopy, result];
      if (_booksByIdBook.containsKey(event.id_book)) {
        _booksByIdBook[event.id_book] = [..._booksByIdBook[event.id_book]!, result];
      }
      emit(BookCopyAddedSuccess(bookCopy: result));
    } catch (e) {
      emit(BookCopyError(e.toString()));
    }
  }

  // ── UPDATE ─────────────────────────────────────────────────────────────────
  Future<void> _updateBookCopy(
      UpdateBookCopyEvent event,
      Emitter<BookCopyState> emit,
      ) async {
    emit(BookCopyLoading());
    try {
      // Tạo object cập nhật từ các field của event
      final updated = BookCopyModel(
        id_copy:       event.id_copy,
        id_book:       event.id_book,
        barcode:       event.barcode,
        qr_code:       event.qr_code,
        location:      event.location,
        received_date: event.received_date,
        condition:     event.condition,
        status:        event.status,
      );

      final result = await bookCopyService.updateBookCopy(updated);

      // Cập nhật cache _allBookCopy
      _allBookCopy = _allBookCopy
          .map((c) => c.id_copy == event.id_copy ? result : c)
          .toList();

      // Cập nhật cache _booksByIdBook
      if (_booksByIdBook.containsKey(event.id_book)) {
        _booksByIdBook[event.id_book] = _booksByIdBook[event.id_book]!
            .map((c) => c.id_copy == event.id_copy ? result : c)
            .toList();
      }

      emit(BookCopyUpdatedSuccess(bookCopy: result));
    } catch (e) {
      emit(BookCopyError(e.toString()));
    }
  }
  }
