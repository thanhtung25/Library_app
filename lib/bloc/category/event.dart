abstract class CategoryEvent {}

class GetAllCategoryEvent extends CategoryEvent {}

class GetCategoriesHasBookEvent extends CategoryEvent {}

// ─── CREATE ───────────────────────────────────────────────────────────────────

class CreateCategoryEvent extends CategoryEvent {
  final String name;
  final String description;
  CreateCategoryEvent({
    required this.name,
    required this.description,
  });
}

// ─── UPDATE ───────────────────────────────────────────────────────────────────

class UpdateCategoryEvent extends CategoryEvent {
  final int id_category;
  final String name;
  final String description;
  UpdateCategoryEvent({
    required this.id_category,
    required this.name,
    required this.description,
  });
}

// ─── DELETE ───────────────────────────────────────────────────────────────────

class DeleteCategoryEvent extends CategoryEvent {
  final int id_category;
  DeleteCategoryEvent({required this.id_category});
}