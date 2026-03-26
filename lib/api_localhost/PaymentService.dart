import '../model/payment_model.dart';
import 'ApiService.dart';

class PaymentService {
  Future<List<PaymentModel>> getAllPayments() async {
    final data = await ApiService.get('/payments-management/payments');
    return (data as List).map((e) => PaymentModel.fromJson(e)).toList();
  }

  Future<PaymentModel> getPaymentById(int id_payment) async {
    final data = await ApiService.get('/payments-management/payment/$id_payment');
    return PaymentModel.fromJson(data);
  }

  Future<PaymentModel> addPayment(PaymentModel payment) async {
    final data = await ApiService.post('/payments-management/payment', payment.toJson());
    return PaymentModel.fromJson(data);
  }

  Future<PaymentModel> updatePayment(PaymentModel payment) async {
    final data = await ApiService.put(
        '/payments-management/payment/${payment.id_payment}', payment.toJson());
    return PaymentModel.fromJson(data);
  }

  Future<void> deletePayment(int id_payment) async {
    await ApiService.delete('/payments-management/payment/$id_payment');
  }

  Future<PaymentModel> createPayment(PaymentModel payment) async {
    final data = await ApiService.post(
      '/payments-management/payment',
      payment.toJson(),
    );
    return PaymentModel.fromJson(data);
  }
}
