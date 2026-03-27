import 'package:bloc/bloc.dart';
import '../../api_localhost/LoanService.dart';
import '../../model/loan_model.dart';
import 'event.dart';
import 'state.dart';

class LoanBloc extends Bloc<LoanEvent, LoanState> {
  final LoanService loanService;

  LoanBloc(this.loanService) : super(LoanInitial()) {
    on<GetAllLoansEvent>(_getAll);
    on<GetLoanByIdEvent>(_getById);
    on<GetLoansByUserIdEvent>(_getByUserId);
    on<AddLoanEvent>(_add);
    on<UpdateLoanEvent>(_update);
    on<DeleteLoanEvent>(_delete);
  }

  Future<void> _getAll(GetAllLoansEvent event, Emitter<LoanState> emit) async {
    emit(LoanLoading());
    try {
      final loans = await loanService.getAllLoans();
      emit(LoanSuccess(loans));
    } catch (e) {
      emit(LoanError(e.toString()));
    }
  }
  Future<void> _getByUserId(
      GetLoansByUserIdEvent event,
      Emitter<LoanState> emit,
      ) async {
    emit(LoanLoading());
    try {
      final loans = await loanService.getLoansByUserId(event.id_user);
      emit(LoanByUserSuccess(loans: loans));
    } catch (e) {
      emit(LoanError(e.toString()));
    }
  }


  Future<void> _getById(GetLoanByIdEvent event, Emitter<LoanState> emit) async {
    emit(LoanLoading());
    try {
      final loan = await loanService.getLoanById(event.id_loan);
      emit(LoanByIdSuccess(loan: loan));
    } catch (e) {
      emit(LoanError(e.toString()));
    }
  }

  Future<void> _add(AddLoanEvent event, Emitter<LoanState> emit) async {
    emit(LoanLoading());
    try {
      await loanService.addLoan(event.loan);
      emit(LoanActionSuccess());
    } catch (e) {
      emit(LoanError(e.toString()));
    }
  }

  Future<void> _update(UpdateLoanEvent event, Emitter<LoanState> emit) async {
    emit(LoanLoading());
    try {
      await loanService.updateLoan(event.loan);
      emit(LoanActionSuccess());
    } catch (e) {
      emit(LoanError(e.toString()));
    }
  }

  Future<void> _delete(DeleteLoanEvent event, Emitter<LoanState> emit) async {
    emit(LoanLoading());
    try {
      await loanService.deleteLoan(event.id_loan);
      emit(LoanActionSuccess());
    } catch (e) {
      emit(LoanError(e.toString()));
    }
  }
}
