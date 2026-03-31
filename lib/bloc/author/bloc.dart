import 'package:bloc/bloc.dart';
import 'package:library_app/api_localhost/AuthorService.dart';

import '../../model/author_model.dart';
import 'event.dart';
import 'state.dart';

class AuthorBloc extends Bloc<AuthorEvent, AuthorState> {
  final Authorservice authorservice;

  AuthorBloc(this.authorservice) : super(AuthorInitial()) {
    on<GetAuthorByIdBookEvent>(_getAuthorByIdBook);
    on<GetAllAuthorsEvent>(_getAllAuthors);
    on<CreateAuthorEvent>(_createAuthor);
    on<UpdateAuthorEvent>(_updateAuthor);
    on<DeleteAuthorEvent>(_deleteAuthor);
  }

  // ─── GET BY ID BOOK ───────────────────────────────────────────────────────

  Future<void> _getAuthorByIdBook(
      GetAuthorByIdBookEvent event,
      Emitter<AuthorState> emit,
      ) async {
    emit(AuthorLoading());
    try {
      final AuthorModel author =
      await authorservice.getAuthorByID(event.id_author);
      emit(AuthorLoadedState(author: author));
    } catch (e) {
      emit(AuthorError(e.toString()));
    }
  }

  // ─── GET ALL ──────────────────────────────────────────────────────────────

  Future<void> _getAllAuthors(
      GetAllAuthorsEvent event,
      Emitter<AuthorState> emit,
      ) async {
    emit(AuthorLoading());
    try {
      final List<AuthorModel> authors = await authorservice.getAllAuthors();
      emit(AuthorListLoaded(authors: authors));
    } catch (e) {
      emit(AuthorError(e.toString()));
    }
  }

  // ─── CREATE ───────────────────────────────────────────────────────────────

  Future<void> _createAuthor(
      CreateAuthorEvent event,
      Emitter<AuthorState> emit,
      ) async {
    emit(AuthorLoading());
    try {
      final AuthorModel author = await authorservice.createAuthor(
        full_name: event.full_name,
        biography: event.biography,
      );
      emit(AuthorCreatedSuccess(author: author));
    } catch (e) {
      emit(AuthorError(e.toString()));
    }
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  Future<void> _updateAuthor(
      UpdateAuthorEvent event,
      Emitter<AuthorState> emit,
      ) async {
    emit(AuthorLoading());
    try {
      final AuthorModel author = await authorservice.updateAuthor(
        id_author: event.id_author,
        full_name: event.full_name,
        biography: event.biography,
      );
      emit(AuthorUpdatedSuccess(author: author));
    } catch (e) {
      emit(AuthorError(e.toString()));
    }
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  Future<void> _deleteAuthor(
      DeleteAuthorEvent event,
      Emitter<AuthorState> emit,
      ) async {
    emit(AuthorLoading());
    try {
      await authorservice.deleteAuthor(id_author: event.id_author);
      emit(AuthorDeletedSuccess(id_author: event.id_author));
    } catch (e) {
      emit(AuthorError(e.toString()));
    }
  }
}