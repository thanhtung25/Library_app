
import '../model/book_model.dart';
import 'ApiService.dart';

class bookService {
  Future<List<BookModel>> getAllBook()async {
    final data = await ApiService.get(
      "/book-management/books",
    );
    return (data as List)
        .map((e) => BookModel.fromJson(e))
        .toList();
  }

  Future<AuthorModel> getAuthorByID(
      int id_author
      )async {
    final data = await ApiService.get(
      "/authors-management/author/${id_author}",
    );
    return AuthorModel.fromJson(data);
  }

  Future<List<BookModel>> getBookByCategory (
      String category
      )async {
    final data = await ApiService.get(
      "/book-management/book/${Uri.encodeComponent(category)}",
    );
    if (data is! List) {
      throw Exception("API did not return List: $data");
    }
    return data
        .map<BookModel>((e) => BookModel.fromJson(e))
        .toList();
  }

  Future<BookModel> getBookById(
      int id_book
      )async{
    final data = await ApiService.get(
      "/book-management/book/${id_book}",
    );
    return BookModel.fromJson(data);
  }
}
