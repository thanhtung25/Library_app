import 'package:bloc/bloc.dart';
import '../../api_localhost/FavoriteService.dart';
import 'event.dart';
import 'state.dart';

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final FavoriteService favoriteService;
  FavoriteBloc(this.favoriteService) : super(FavoriteInitial()) {
    on<GetAllFavoritesEvent>((e, emit) async {
      emit(FavoriteLoading());
      try { emit(FavoriteSuccess(await favoriteService.getAllFavorites())); }
      catch (err) { emit(FavoriteError(err.toString())); }
    });
    on<GetFavoriteByIdEvent>((e, emit) async {
      emit(FavoriteLoading());
      try { emit(FavoriteByIdSuccess(favorite: await favoriteService.getFavoriteById(e.id_favorite))); }
      catch (err) { emit(FavoriteError(err.toString())); }
    });
    on<AddFavoriteEvent>((e, emit) async {
      emit(FavoriteLoading());
      try { await favoriteService.addFavorite(e.favorite); emit(FavoriteActionSuccess()); }
      catch (err) { emit(FavoriteError(err.toString())); }
    });
    on<DeleteFavoriteEvent>((e, emit) async {
      emit(FavoriteLoading());
      try { await favoriteService.deleteFavorite(e.id_favorite); emit(FavoriteActionSuccess()); }
      catch (err) { emit(FavoriteError(err.toString())); }
    });
  }
}
