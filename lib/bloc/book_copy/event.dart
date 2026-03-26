abstract class BookCopyEvent {}

class GetBookCopyEvent extends BookCopyEvent {
}

class GetBookByIdBookEvent extends BookCopyEvent {
  final int id_book;
  GetBookByIdBookEvent({required this.id_book});
}