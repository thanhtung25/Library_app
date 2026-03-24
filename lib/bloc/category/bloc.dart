import 'package:bloc/bloc.dart';
import 'package:library_app/api_localhost/CategorySevice.dart';
import 'package:library_app/bloc/category/event.dart';

import 'event.dart';
import 'state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryService categoryService;
  CategoryBloc(this.categoryService) : super(CategoryInitial()){
    on<GetAllCategoryEvent>(_getAllCategory);
    on<GetCategoriesHasBookEvent>(_getCategoriesHasBook);
  }
  Future<void> _getAllCategory(
      GetAllCategoryEvent event,
      Emitter<CategoryState> emit,
      )async{
      emit(CategoryLoading());
      try{
        final category = await CategoryService().getAllCategory();
        emit(CategorySuccess(category));
      }catch(e){
        emit(CategoryError(e.toString()));
      }
  }

  Future<void> _getCategoriesHasBook(
      GetCategoriesHasBookEvent event,
      Emitter<CategoryState> emit,
      )async{
    emit(CategoryLoading());
    try{
      final category = await CategoryService().getCategoriesHasBooks();
      emit(CategorySuccess(category));
    }catch(e){
      emit(CategoryError(e.toString()));
    }
  }
}
