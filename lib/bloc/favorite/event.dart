import '../../model/favorite_model.dart';
abstract class FavoriteEvent {}
class GetAllFavoritesEvent extends FavoriteEvent {}
class GetFavoriteByIdEvent extends FavoriteEvent { final int id_favorite; GetFavoriteByIdEvent({required this.id_favorite}); }
class AddFavoriteEvent extends FavoriteEvent { final FavoriteModel favorite; AddFavoriteEvent({required this.favorite}); }
class DeleteFavoriteEvent extends FavoriteEvent { final int id_favorite; DeleteFavoriteEvent({required this.id_favorite}); }
