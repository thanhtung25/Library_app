class DeliveryModel {
  final int? id_delivery;
  final int id_reservation;
  final String address;
  final double price;
  final DateTime? created_at;
  final DateTime? delivery_date;
  final String status;

  DeliveryModel({
    this.id_delivery, required this.id_reservation, required this.address,
    this.price = 0, this.created_at, this.delivery_date, this.status = 'pending',
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id_delivery: json['id_delivery'],
      id_reservation: json['id_reservation'] ?? 0,
      address: json['address'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      created_at: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) : null,
      delivery_date: json['delivery_date'] != null
          ? DateTime.tryParse(json['delivery_date'].toString()) : null,
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_delivery': id_delivery, 'id_reservation': id_reservation,
      'address': address, 'price': price,
      'created_at': created_at?.toIso8601String(),
      'delivery_date': delivery_date?.toIso8601String(), 'status': status,
    };
  }

  DeliveryModel copyWith({
    int? id_delivery, int? id_reservation, String? address, double? price,
    DateTime? created_at, DateTime? delivery_date, String? status,
  }) {
    return DeliveryModel(
      id_delivery: id_delivery ?? this.id_delivery,
      id_reservation: id_reservation ?? this.id_reservation,
      address: address ?? this.address, price: price ?? this.price,
      created_at: created_at ?? this.created_at,
      delivery_date: delivery_date ?? this.delivery_date, status: status ?? this.status,
    );
  }
}
