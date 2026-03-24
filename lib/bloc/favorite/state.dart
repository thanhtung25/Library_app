import '../../model/favorite_model.dart';
abstract class FavoriteState {}
class FavoriteInitial extends FavoriteState {}
class FavoriteLoading extends FavoriteState {}
class FavoriteSuccess extends FavoriteState { final List<FavoriteModel> favorites; FavoriteSuccess(this.favorites); }
class FavoriteByIdSuccess extends FavoriteState { final FavoriteModel favorite; FavoriteByIdSuccess({required this.favorite}); }
class FavoriteActionSuccess extends FavoriteState {}
class FavoriteError extends FavoriteState { final String message; FavoriteError(this.message); }
