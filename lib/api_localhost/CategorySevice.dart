import '../model/category_model.dart';
import 'ApiService.dart';

class CategoryService{
  Future<List<CategoryModel>> getAllCategory() async{
    final data = await ApiService.get("/categories-management/categories",);

    print(data);
    return (data as List)
        .map((e) => CategoryModel.fromJson(e))
        .toList();
  }

  Future<List<CategoryModel>> getCategoriesHasBooks() async{
    final data = await ApiService.get("/categories-management/categories/has-books",);

    print(data);
    return (data as List)
        .map((e) => CategoryModel.fromJson(e))
        .toList();
  }
}