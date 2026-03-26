import 'package:bloc/bloc.dart';
import 'package:library_app/api_localhost/FavoriteService.dart';

import '../../model/favorite_model.dart';
import 'event.dart';
import 'state.dart';

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final FavoriteService favoriteService;
  List<FavoriteModel> _allFavorites = [];
  Map<int, List<FavoriteModel>> _favoritesByUser = {};

  FavoriteBloc(this.favoriteService) : super(FavoriteInitial()) {
    on<GetAllFavoritesEvent>(_getAllFavorites);
    on<GetFavoritesByUserIdEvent>(_getFavoritesByUserId);
    on<GetFavoriteByIdEvent>(_getFavoriteById);
    on<AddFavoriteEvent>(_addFavorite);
    on<DeleteFavoriteEvent>(_deleteFavorite);
  }

  Future<void> _getAllFavorites(
      GetAllFavoritesEvent event,
      Emitter<FavoriteState> emit,
      ) async {
    emit(FavoriteLoading());
    try {
      final favorites = await favoriteService.getAllFavorites();
      _allFavorites = favorites;
      emit(FavoriteSuccess(favorites));
    } catch (e) {
      emit(FavoriteError(e.toString()));
    }
  }

  Future<void> _getFavoritesByUserId(
      GetFavoritesByUserIdEvent event,
      Emitter<FavoriteState> emit,
      ) async {
    try {
      final favorites = await favoriteService.getFavoritesByUserId(event.id_user);
      _favoritesByUser[event.id_user] = favorites;
      emit(FavoriteByUserSuccess(
        Map.from(_favoritesByUser),
        _allFavorites,
      ));
    } catch (e) {
      emit(FavoriteError(e.toString()));
    }
  }

  Future<void> _getFavoriteById(
      GetFavoriteByIdEvent event,
      Emitter<FavoriteState> emit,
      ) async {
    emit(FavoriteLoading());
    try {
      final favorite = await favoriteService.getFavoriteById(event.id_favorite);
      emit(FavoriteByIdSuccess(favorite: favorite));
    } catch (e) {
      emit(FavoriteError(e.toString()));
    }
  }

  Future<void> _addFavorite(
      AddFavoriteEvent event,
      Emitter<FavoriteState> emit,
      ) async {
    try {
      await favoriteService.addFavorite(event.favorite);
      emit(FavoriteActionSuccess());
    } catch (e) {
      emit(FavoriteError(e.toString()));
    }
  }

  Future<void> _deleteFavorite(
      DeleteFavoriteEvent event,
      Emitter<FavoriteState> emit,
      ) async {
    try {
      await favoriteService.deleteFavorite(event.id_favorite);
      emit(FavoriteActionSuccess());
    } catch (e) {
      emit(FavoriteError(e.toString()));
    }
  }
}