import '../../model/loan_model.dart';

abstract class LoanState {}
class LoanInitial extends LoanState {}
class LoanLoading extends LoanState {}
class LoanSuccess extends LoanState {
  final List<LoanModel> loans;
  LoanSuccess(this.loans);
}
class LoanByIdSuccess extends LoanState {
  final LoanModel loan;
  LoanByIdSuccess({required this.loan});
}
class LoanActionSuccess extends LoanState {}
class LoanError extends LoanState {
  final String message;
  LoanError(this.message);
}
