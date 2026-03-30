import 'package:bloc/bloc.dart';
import 'package:library_app/api_localhost/CategorySevice.dart';

import 'event.dart';
import 'state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryService categoryService;

  CategoryBloc(this.categoryService) : super(CategoryInitial()) {
    on<GetAllCategoryEvent>(_getAllCategory);
    on<GetCategoriesHasBookEvent>(_getCategoriesHasBook);
    on<CreateCategoryEvent>(_createCategory);
    on<UpdateCategoryEvent>(_updateCategory);
    on<DeleteCategoryEvent>(_deleteCategory);
  }

  // ─── GET ALL ──────────────────────────────────────────────────────────────

  Future<void> _getAllCategory(
      GetAllCategoryEvent event,
      Emitter<CategoryState> emit,
      ) async {
    emit(CategoryLoading());
    try {
      final categories = await categoryService.getAllCategory();
      emit(CategorySuccess(categories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  // ─── GET HAS BOOKS ────────────────────────────────────────────────────────

  Future<void> _getCategoriesHasBook(
      GetCategoriesHasBookEvent event,
      Emitter<CategoryState> emit,
      ) async {
    emit(CategoryLoading());
    try {
      final categories = await categoryService.getCategoriesHasBooks();
      emit(CategorySuccess(categories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  // ─── CREATE ───────────────────────────────────────────────────────────────

  Future<void> _createCategory(
      CreateCategoryEvent event,
      Emitter<CategoryState> emit,
      ) async {
    emit(CategoryLoading());
    try {
      final category = await categoryService.createCategory(
        name: event.name,
        description: event.description,
      );
      emit(CategoryCreatedSuccess(category: category));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  Future<void> _updateCategory(
      UpdateCategoryEvent event,
      Emitter<CategoryState> emit,
      ) async {
    emit(CategoryLoading());
    try {
      final category = await categoryService.updateCategory(
        id_category: event.id_category,
        name: event.name,
        description: event.description,
      );
      emit(CategoryUpdatedSuccess(category: category));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  Future<void> _deleteCategory(
      DeleteCategoryEvent event,
      Emitter<CategoryState> emit,
      ) async {
    emit(CategoryLoading());
    try {
      await categoryService.deleteCategory(id_category: event.id_category);
      emit(CategoryDeletedSuccess(id_category: event.id_category));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
}