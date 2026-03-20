
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

  Future<List<CategoryModel>> getAllCategory() async{
    final data = await ApiService.get("/categories-management/categories",);

    print(data);
    return (data as List)
        .map((e) => CategoryModel.fromJson(e))
    .toList();
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

}
