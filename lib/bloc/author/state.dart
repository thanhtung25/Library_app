import '../../model/author_model.dart';

abstract class AuthorState {}

// ─── BASE ─────────────────────────────────────────────────────────────────────

class AuthorInitial extends AuthorState {}

class AuthorLoading extends AuthorState {}

class AuthorError extends AuthorState {
  final String message;
  AuthorError(this.message);
}

// ─── GET ──────────────────────────────────────────────────────────────────────

class AuthorLoadedState extends AuthorState {
  final AuthorModel author;
  AuthorLoadedState({required this.author});
}

class AuthorListLoaded extends AuthorState {
  final List<AuthorModel> authors;
  AuthorListLoaded({required this.authors});
}

// ─── CREATE ───────────────────────────────────────────────────────────────────

class AuthorCreatedSuccess extends AuthorState {
  final AuthorModel author;
  AuthorCreatedSuccess({required this.author});
}

// ─── UPDATE ───────────────────────────────────────────────────────────────────

class AuthorUpdatedSuccess extends AuthorState {
  final AuthorModel author;
  AuthorUpdatedSuccess({required this.author});
}

// ─── DELETE ───────────────────────────────────────────────────────────────────

class AuthorDeletedSuccess extends AuthorState {
  final int id_author;
  AuthorDeletedSuccess({required this.id_author});
}