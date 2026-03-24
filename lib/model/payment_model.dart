class PaymentModel {
  final int? id_payment;
  final int id_user;
  final int? id_fine;
  final int? id_delivery;
  final String payment_type;
  final double amount;
  final DateTime? payment_date;
  final String? payment_method;
  final String? document_number;
  final String status;

  PaymentModel({
    this.id_payment, required this.id_user, this.id_fine, this.id_delivery,
    required this.payment_type, this.amount = 0, this.payment_date,
    this.payment_method, this.document_number, this.status = 'paid',
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id_payment: json['id_payment'], id_user: json['id_user'] ?? 0,
      id_fine: json['id_fine'], id_delivery: json['id_delivery'],
      payment_type: json['payment_type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      payment_date: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'].toString()) : null,
      payment_method: json['payment_method'],
      document_number: json['document_number'],
      status: json['status'] ?? 'paid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_payment': id_payment, 'id_user': id_user,
      'id_fine': id_fine, 'id_delivery': id_delivery,
      'payment_type': payment_type, 'amount': amount,
      'payment_date': payment_date?.toIso8601String(),
      'payment_method': payment_method, 'document_number': document_number, 'status': status,
    };
  }

  PaymentModel copyWith({
    int? id_payment, int? id_user, int? id_fine, int? id_delivery,
    String? payment_type, double? amount, DateTime? payment_date,
    String? payment_method, String? document_number, String? status,
  }) {
    return PaymentModel(
      id_payment: id_payment ?? this.id_payment, id_user: id_user ?? this.id_user,
      id_fine: id_fine ?? this.id_fine, id_delivery: id_delivery ?? this.id_delivery,
      payment_type: payment_type ?? this.payment_type, amount: amount ?? this.amount,
      payment_date: payment_date ?? this.payment_date,
      payment_method: payment_method ?? this.payment_method,
      document_number: document_number ?? this.document_number, status: status ?? this.status,
    );
  }
}
