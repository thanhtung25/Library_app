import '../model/book_copy_model.dart';
import 'ApiService.dart';

class BookCopyService {
  Future<List<BookCopyModel>> getAllBookCopies() async {
    final data = await ApiService.get('/book_copies-management/book_copies');
    return (data as List).map((e) => BookCopyModel.fromJson(e)).toList();
  }

  Future<BookCopyModel> getBookCopyById(int id_copy) async {
    final data = await ApiService.get('/book_copies-management/book_copy/$id_copy');
    return BookCopyModel.fromJson(data);
  }

  Future<BookCopyModel> addBookCopy(BookCopyModel bookCopy) async {
    final data = await ApiService.post('/book_copies-management/book_copy', bookCopy.toJson());
    return BookCopyModel.fromJson(data);
  }

  Future<BookCopyModel> updateBookCopy(BookCopyModel bookCopy) async {
    final data = await ApiService.put(
        '/book_copies-management/book_copy/${bookCopy.id_copy}', bookCopy.toJson());
    return BookCopyModel.fromJson(data);
  }

  Future<void> deleteBookCopy(int id_copy) async {
    await ApiService.delete('/book_copies-management/book_copy/$id_copy');
  }
}
