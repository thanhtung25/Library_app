
class ReservationModel{
  final int? id_reservation;
  final int id_user;
  final int id_book;
  final DateTime? reservation_date;
  final DateTime? expiration_date;
  final String? comment;
  final String status;

  ReservationModel({
    this.id_reservation,
    required this.id_user,
    required this.id_book,
    this.reservation_date,
    this.expiration_date,
    this.comment,
    this.status = 'pending',
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id_reservation: json['id_reservation'],
      id_user: json['id_user'],
      id_book: json['id_book'],
      reservation_date: json['reservation_date'] != null
          ? DateTime.parse(json['reservation_date'])
          : null,
      expiration_date: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'])
          : null,
      comment: json['comment'],
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_reservation': id_reservation,
      'id_user': id_user,
      'id_book': id_book,
      'reservation_date': reservation_date?.toIso8601String(),
      'expiration_date': expiration_date?.toIso8601String(),
      'comment': comment,
      'status': status,
    };
  }

  ReservationModel copyWith({
    int? id_reservation,
    int? id_user,
    int? id_book,
    DateTime? reservation_date,
    DateTime? expiration_date,
    String? comment,
    String? status,
  }) {
    return ReservationModel(
      id_reservation: id_reservation ?? this.id_reservation,
      id_user: id_user ?? this.id_user,
      id_book: id_book ?? this.id_book,
      reservation_date: reservation_date ?? this.reservation_date,
      expiration_date: expiration_date ?? this.expiration_date,
      comment: comment ?? this.comment,
      status: status ?? this.status,
    );
  }
}