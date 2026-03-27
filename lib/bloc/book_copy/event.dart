abstract class BookCopyEvent {}

class GetBookCopyEvent extends BookCopyEvent {
}

class GetBookByIdBookEvent extends BookCopyEvent {
  final int id_book;
  GetBookByIdBookEvent({required this.id_book});
}

class UpdateBookCopyEvent extends BookCopyEvent {
  final int    id_copy;
  final int    id_book;
  final String barcode;
  final String? qr_code;
  final String? location;
  final DateTime? received_date;
  final String? condition;
  final String  status;

  UpdateBookCopyEvent({
    required this.id_copy,
    required this.id_book,
    required this.barcode,
    this.qr_code,
    this.location,
    this.received_date,
    this.condition,
    required this.status,
  });
}