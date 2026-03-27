import '../model/loan_model.dart';
import 'ApiService.dart';

class LoanService {
  Future<List<LoanModel>> getAllLoans() async {
    final data = await ApiService.get('/loans-management/loans');
    return (data as List).map((e) => LoanModel.fromJson(e)).toList();
  }

  Future<LoanModel> getLoanById(int id_loan) async {
    final data = await ApiService.get('/loans-management/loan/$id_loan');
    return LoanModel.fromJson(data);
  }

  Future<List<LoanModel>> getLoansByUserId(int id_user) async {
    final data = await ApiService.get('/loans-management/loan/user/$id_user');
    return (data as List).map((e) => LoanModel.fromJson(e)).toList();
  }

  Future<LoanModel> addLoan(LoanModel loan) async {
    final data = await ApiService.post('/loans-management/loan', loan.toJson());
    return LoanModel.fromJson(data);
  }

  Future<LoanModel> updateLoan(LoanModel loan) async {
    final data = await ApiService.put(
        '/loans-management/loan/${loan.id_loan}', loan.toJson());
    return LoanModel.fromJson(data);
  }

  Future<void> deleteLoan(int id_loan) async {
    await ApiService.delete('/loans-management/loan/$id_loan');
  }
}
