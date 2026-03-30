abstract class AuthorEvent {}

class InitEvent extends AuthorEvent {}

// ─── GET ──────────────────────────────────────────────────────────────────────

class GetAuthorByIdBookEvent extends AuthorEvent {
  final int id_book;
  GetAuthorByIdBookEvent({required this.id_book});
}

class GetAllAuthorsEvent extends AuthorEvent {}

// ─── CREATE ───────────────────────────────────────────────────────────────────

class CreateAuthorEvent extends AuthorEvent {
  final String full_name;
  final String biography;
  CreateAuthorEvent({
    required this.full_name,
    required this.biography,
  });
}

// ─── UPDATE ───────────────────────────────────────────────────────────────────

class UpdateAuthorEvent extends AuthorEvent {
  final int id_author;
  final String full_name;
  final String biography;
  UpdateAuthorEvent({
    required this.id_author,
    required this.full_name,
    required this.biography,
  });
}

// ─── DELETE ───────────────────────────────────────────────────────────────────

class DeleteAuthorEvent extends AuthorEvent {
  final int id_author;
  DeleteAuthorEvent({required this.id_author});
}