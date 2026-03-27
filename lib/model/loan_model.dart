class LoanModel {
  final int? id_loan;
  final int id_user;
  final int id_copy;
  final DateTime? issue_date;
  final DateTime return_date;
  final DateTime? actual_return_date;
  final String status;
  final int renewal_count;

  LoanModel({
    this.id_loan,
    required this.id_user,
    required this.id_copy,
    required this.issue_date,
    required this.return_date,
    this.actual_return_date,
    this.status = 'borrowed',
    this.renewal_count = 0,
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id_loan: json['id_loan'],
      id_user: json['id_user'] ?? 0,
      id_copy: json['id_copy'] ?? 0,
      issue_date: DateTime.parse(json['issue_date']),
      return_date: DateTime.parse(json['return_date']),
      actual_return_date: json['actual_return_date'] != null
          ? DateTime.tryParse(json['actual_return_date'].toString())
          : null,
      status: json['status'] ?? 'borrowed',
      renewal_count: json['renewal_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_loan': id_loan, 'id_user': id_user, 'id_copy': id_copy,
      'issue_date': issue_date?.toIso8601String().split('T')[0],
      'return_date': return_date.toIso8601String().split('T')[0],
      'actual_return_date': actual_return_date?.toIso8601String().split('T')[0],
      'status': status, 'renewal_count': renewal_count,
    };
  }

  LoanModel copyWith({
    int? id_loan, int? id_user, int? id_copy,
    DateTime? issue_date, DateTime? return_date, DateTime? actual_return_date,
    String? status, int? renewal_count,
  }) {
    return LoanModel(
      id_loan: id_loan ?? this.id_loan, id_user: id_user ?? this.id_user,
      id_copy: id_copy ?? this.id_copy, issue_date: issue_date ?? this.issue_date,
      return_date: return_date ?? this.return_date,
      actual_return_date: actual_return_date ?? this.actual_return_date,
      status: status ?? this.status, renewal_count: renewal_count ?? this.renewal_count,
    );
  }
}
