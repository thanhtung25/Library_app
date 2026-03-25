import '../model/delivery_model.dart';
import 'ApiService.dart';

class DeliveryService {
  Future<List<DeliveryModel>> getAllDeliveries() async {
    final data = await ApiService.get('/delivery-management/deliveries');
    return (data as List).map((e) => DeliveryModel.fromJson(e)).toList();
  }

  Future<DeliveryModel> getDeliveryById(int id_delivery) async {
    final data = await ApiService.get('/delivery-management/delivery/$id_delivery');
    return DeliveryModel.fromJson(data);
  }

  Future<DeliveryModel> addDelivery(DeliveryModel delivery) async {
    final data = await ApiService.post('/delivery-management/delivery', delivery.toJson());
    return DeliveryModel.fromJson(data);
  }

  Future<DeliveryModel> updateDelivery(DeliveryModel delivery) async {
    final data = await ApiService.put(
        '/delivery-management/delivery/${delivery.id_delivery}', delivery.toJson());
    return DeliveryModel.fromJson(data);
  }

  Future<void> deleteDelivery(int id_delivery) async {
    await ApiService.delete('/delivery-management/delivery/$id_delivery');
  }

  Future<DeliveryModel> createDelivery(DeliveryModel delivery) async {
    final data = await ApiService.post(
      '/delivery-management/delivery',
      delivery.toJson(),
    );
    return DeliveryModel.fromJson(data);
  }
}
