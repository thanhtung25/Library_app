import '../model/fine_model.dart';
import 'ApiService.dart';

class FineService {
  Future<List<FineModel>> getAllFines() async {
    final data = await ApiService.get('/fines-management/fines');
    return (data as List).map((e) => FineModel.fromJson(e)).toList();
  }

  Future<FineModel> getFineById(int id_fine) async {
    final data = await ApiService.get('/fines-management/fine/$id_fine');
    return FineModel.fromJson(data);
  }

  Future<FineModel> addFine(FineModel fine) async {
    final data = await ApiService.post('/fines-management/fine', fine.toJson());
    return FineModel.fromJson(data);
  }

  Future<FineModel> updateFine(FineModel fine) async {
    final data = await ApiService.put(
        '/fines-management/fine/${fine.id_fine}', fine.toJson());
    return FineModel.fromJson(data);
  }

  Future<void> deleteFine(int id_fine) async {
    await ApiService.delete('/fines-management/fine/$id_fine');
  }
}
