

import 'package:library_app/model/category_model.dart';

abstract class CategoryState {}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategorySuccess extends CategoryState {
  final List<CategoryModel> category;
  CategorySuccess(this.category);
}

class CategoryError extends CategoryState {
  final String message;
  CategoryError(this.message);
}

