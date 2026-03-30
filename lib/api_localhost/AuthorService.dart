import '../model/author_model.dart';
import 'ApiService.dart';

class Authorservice {

  // ─── GET BY ID ────────────────────────────────────────────────────────────

  Future<AuthorModel> getAuthorByID(int id_author) async {
    final data = await ApiService.get(
      "/authors-management/author/$id_author",
    );
    return AuthorModel.fromJson(data);
  }

  // ─── GET ALL ──────────────────────────────────────────────────────────────

  Future<List<AuthorModel>> getAllAuthors() async {
    final data = await ApiService.get("/authors-management/authors");
    return (data as List).map((e) => AuthorModel.fromJson(e)).toList();
  }

  // ─── CREATE ───────────────────────────────────────────────────────────────

  Future<AuthorModel> createAuthor({
    required String full_name,
    required String biography,
  }) async {
    final data = await ApiService.post(
      "/authors-management/author",
      {
        "full_name": full_name,
        "biography": biography,
      },
    );
    return AuthorModel.fromJson(data);
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  Future<AuthorModel> updateAuthor({
    required int id_author,
    required String full_name,
    required String biography,
  }) async {
    final data = await ApiService.put(
      "/authors-management/author/$id_author",
      {
        "full_name": full_name,
        "biography": biography,
      },
    );
    return AuthorModel.fromJson(data);
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  Future<void> deleteAuthor({required int id_author}) async {
    await ApiService.delete("/authors-management/author/$id_author");
  }
}