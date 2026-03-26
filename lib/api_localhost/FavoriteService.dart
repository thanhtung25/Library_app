import '../model/favorite_model.dart';
import 'ApiService.dart';

class FavoriteService {
  Future<List<FavoriteModel>> getAllFavorites() async {
    final data = await ApiService.get('/favorites-management/favorites');
    return (data as List).map((e) => FavoriteModel.fromJson(e)).toList();
  }

  Future<FavoriteModel> getFavoriteById(int id_favorite) async {
    final data = await ApiService.get('/favorites-management/favorite/$id_favorite');
    return FavoriteModel.fromJson(data);
  }

  Future<FavoriteModel> addFavorite(FavoriteModel favorite) async {
    final data = await ApiService.post('/favorites-management/favorite', favorite.toJson());
    return FavoriteModel.fromJson(data);
  }

  Future<void> deleteFavorite(int id_favorite) async {
    await ApiService.delete('/favorites-management/favorite/$id_favorite');
  }
  Future<List<FavoriteModel>> getFavoritesByUserId(int id_user) async {
    final data = await ApiService.get('/favorites-management/favorites/user/$id_user');
    return (data as List).map((e) => FavoriteModel.fromJson(e)).toList();
  }
}
