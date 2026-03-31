// Model local cho Loan Management (riêng biệt với LoanModel của BLoC)
class LoanItem {
  final int    idLoan;
  final int    idUser;
  final int    idCopy;
  final int    renewalCount;
  final String issueDate;
  final String returnDate;
  final String status;
  final String? actualReturnDate;

  const LoanItem({
    required this.idLoan,
    required this.idUser,
    required this.idCopy,
    required this.renewalCount,
    required this.issueDate,
    required this.returnDate,
    required this.status,
    this.actualReturnDate,
  });

  factory LoanItem.fromJson(Map<String, dynamic> j) => LoanItem(
    idLoan:           j['id_loan']            ?? 0,
    idUser:           j['id_user']            ?? 0,
    idCopy:           j['id_copy']            ?? 0,
    renewalCount:     j['renewal_count']      ?? 0,
    issueDate:        j['issue_date']         ?? '',
    returnDate:       j['return_date']        ?? '',
    status:           j['status']             ?? 'borrowed',
    actualReturnDate: j['actual_return_date']?.toString(),
  );

  DateTime? get returnDateTime => DateTime.tryParse(returnDate);

  int get daysOverdue {
    final rd = returnDateTime;
    if (rd == null) return 0;
    final diff = DateTime.now().difference(rd).inDays;
    return diff > 0 ? diff : 0;
  }

  int get daysUntilReturn {
    final rd = returnDateTime;
    if (rd == null) return 999;
    return rd.difference(DateTime.now()).inDays;
  }

  bool get isNearDeadline =>
      status == 'borrowed' && daysUntilReturn <= 3 && daysUntilReturn >= 0;
}
