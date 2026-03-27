
import '../model/book_model.dart';
import 'ApiService.dart';

class bookService {

  // READ
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


  //CREATE
  Future<BookModel> createBook(
      { required int id_category,
        required int id_author,
        required String title,
        required String isbn,
        required String language,
        required int publish_year,
        required String description,
        required String image_url,
        required DateTime? created_at,}
      )async{
    final data = await ApiService.post(
        "/book-management/book",
        {
          'id_category': id_category,
          'id_author': id_author,
          'title': title,
          'isbn': isbn,
          'language': language,
          'publish_year': publish_year,
          'description': description,
          'image_url': image_url,
          'created_at': created_at?.toIso8601String(),
        });
    return BookModel.fromJson(data);
    }

    // UPDATE
    Future<BookModel> updateBook({
      required int id_book,
      required int id_category,
      required int id_author,
      required String title,
      required String isbn,
      required String language,
      required int publish_year,
      required String description,
      required String image_url,
      required DateTime? created_at,
    }) async {
      final data = await ApiService.put(
          "/book-management/book/${id_book}",
          {
            'id_category': id_category,
            'id_author': id_author,
            'title': title,
            'isbn': isbn,
            'language': language,
            'publish_year': publish_year,
            'description': description,
            'image_url': image_url,
            'created_at': created_at?.toIso8601String(),
          });
      return BookModel.fromJson(data);
    }
  // DELETE
  Future<void> deleteBook(
      int id_book
      ) async {
    await ApiService.delete(
      "/book-management/book/${id_book}",
    );
  }
}
