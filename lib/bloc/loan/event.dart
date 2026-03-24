import '../../model/loan_model.dart';

abstract class LoanEvent {}

class GetAllLoansEvent extends LoanEvent {}

class GetLoanByIdEvent extends LoanEvent {
  final int id_loan;
  GetLoanByIdEvent({required this.id_loan});
}

class AddLoanEvent extends LoanEvent {
  final LoanModel loan;    // import loan_model.dart
  AddLoanEvent({required this.loan});
}

class UpdateLoanEvent extends LoanEvent {
  final LoanModel loan;
  UpdateLoanEvent({required this.loan});
}

class DeleteLoanEvent extends LoanEvent {
  final int id_loan;
  DeleteLoanEvent({required this.id_loan});
}
