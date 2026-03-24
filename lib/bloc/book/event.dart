

abstract class BookEvent {}

class GetBookEvent extends BookEvent {
}


class GetBookByCategoryEvent extends BookEvent {
  final String category;
  GetBookByCategoryEvent({required this.category});
}

class GetBookByIdEvent extends BookEvent{
  final int id_book;
  GetBookByIdEvent({required this.id_book});
}

class GetAuthorByIdBookEvent extends BookEvent{
  final int id_book;
  GetAuthorByIdBookEvent({required this.id_book});
}
