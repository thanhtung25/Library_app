class BookCopyModel {
  final int? id_copy;
  final int id_book;
  final String barcode;
  final String? qr_code;
  final String? location;
  final DateTime? received_date;
  final String? condition;
  final String status;

  BookCopyModel({
    this.id_copy,
    required this.id_book,
    required this.barcode,
    this.qr_code,
    this.location,
    this.received_date,
    this.condition,
    this.status = 'available',
  });

  factory BookCopyModel.fromJson(Map<String, dynamic> json) {
    return BookCopyModel(
      id_copy: json['id_copy'],
      id_book: json['id_book'] ?? 0,
      barcode: json['barcode'] ?? '',
      qr_code: json['qr_code'],
      location: json['location'],
      received_date: json['received_date'] != null
          ? DateTime.tryParse(json['received_date'].toString())
          : null,
      condition: json['condition'],
      status: json['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_copy': id_copy,
      'id_book': id_book,
      'barcode': barcode,
      'qr_code': qr_code,
      'location': location,
      'received_date': received_date?.toIso8601String().split('T')[0],
      'condition': condition,
      'status': status,
    };
  }

  BookCopyModel copyWith({
    int? id_copy, int? id_book, String? barcode, String? qr_code,
    String? location, DateTime? received_date, String? condition, String? status,
  }) {
    return BookCopyModel(
      id_copy: id_copy ?? this.id_copy, id_book: id_book ?? this.id_book,
      barcode: barcode ?? this.barcode, qr_code: qr_code ?? this.qr_code,
      location: location ?? this.location, received_date: received_date ?? this.received_date,
      condition: condition ?? this.condition, status: status ?? this.status,
    );
  }
}
