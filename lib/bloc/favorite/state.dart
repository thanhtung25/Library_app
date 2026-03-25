import '../../model/favorite_model.dart';

abstract class FavoriteState {}

class FavoriteInitial extends FavoriteState {}

class FavoriteLoading extends FavoriteState {}

class FavoriteSuccess extends FavoriteState {
  final List<FavoriteModel> favorites;
  FavoriteSuccess(this.favorites);
}

class FavoriteByUserSuccess extends FavoriteState {
  final Map<int, List<FavoriteModel>> favoritesByUser;
  final List<FavoriteModel> allFavorites;

  FavoriteByUserSuccess(this.favoritesByUser, this.allFavorites);

  // Helper tiện dụng
  List<FavoriteModel> getByUser(int idUser) =>
      favoritesByUser[idUser] ?? [];
}
class FavoriteByIdSuccess extends FavoriteState {
  final FavoriteModel favorite;
  FavoriteByIdSuccess({required this.favorite});
}

class FavoriteActionSuccess extends FavoriteState {}

class FavoriteError extends FavoriteState {
  final String message;
  FavoriteError(this.message);
}