import '../model/category_model.dart';
import 'ApiService.dart';

class CategoryService {

  // ─── GET ALL ──────────────────────────────────────────────────────────────

  Future<List<CategoryModel>> getAllCategory() async {
    final data = await ApiService.get("/categories-management/categories");
    return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  // ─── GET HAS BOOKS ────────────────────────────────────────────────────────

  Future<List<CategoryModel>> getCategoriesHasBooks() async {
    final data = await ApiService.get(
      "/categories-management/categories/has-books",
    );
    return (data as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  // ─── CREATE ───────────────────────────────────────────────────────────────

  Future<CategoryModel> createCategory({
    required String name,
    required String description,
  }) async {
    final data = await ApiService.post(
      "/categories-management/category",
      {
        "name": name,
        "description": description,
      },
    );
    return CategoryModel.fromJson(data);
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  Future<CategoryModel> updateCategory({
    required int id_category,
    required String name,
    required String description,
  }) async {
    final data = await ApiService.put(
      "/categories-management/category/$id_category",
      {
        "name": name,
        "description": description,
      },
    );
    return CategoryModel.fromJson(data);
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  Future<void> deleteCategory({required int id_category}) async {
    await ApiService.delete(
      "/categories-management/category/$id_category",
    );
  }
}