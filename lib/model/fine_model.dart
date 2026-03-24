class FineModel {
  final int? id_fine;
  final int id_loan;
  final double amount;
  final String? reason;
  final DateTime? created_at;
  final String status;

  FineModel({
    this.id_fine, required this.id_loan, this.amount = 0,
    this.reason, this.created_at, this.status = 'unpaid',
  });

  factory FineModel.fromJson(Map<String, dynamic> json) {
    return FineModel(
      id_fine: json['id_fine'],
      id_loan: json['id_loan'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      reason: json['reason'],
      created_at: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) : null,
      status: json['status'] ?? 'unpaid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_fine': id_fine, 'id_loan': id_loan, 'amount': amount,
      'reason': reason, 'created_at': created_at?.toIso8601String(), 'status': status,
    };
  }

  FineModel copyWith({
    int? id_fine, int? id_loan, double? amount,
    String? reason, DateTime? created_at, String? status,
  }) {
    return FineModel(
      id_fine: id_fine ?? this.id_fine, id_loan: id_loan ?? this.id_loan,
      amount: amount ?? this.amount, reason: reason ?? this.reason,
      created_at: created_at ?? this.created_at, status: status ?? this.status,
    );
  }
}
