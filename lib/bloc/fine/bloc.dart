import 'package:bloc/bloc.dart';
import '../../api_localhost/FineService.dart';
import 'event.dart';
import 'state.dart';

class FineBloc extends Bloc<FineEvent, FineState> {
  final FineService fineService;
  FineBloc(this.fineService) : super(FineInitial()) {
    on<GetAllFinesEvent>((e, emit) async {
      emit(FineLoading());
      try { emit(FineSuccess(await fineService.getAllFines())); }
      catch (e) { emit(FineError(e.toString())); }
    });
    on<GetFineByIdEvent>((e, emit) async {
      emit(FineLoading());
      try { emit(FineByIdSuccess(fine: await fineService.getFineById(e.id_fine))); }
      catch (err) { emit(FineError(err.toString())); }
    });
    on<AddFineEvent>((e, emit) async {
      emit(FineLoading());
      try { await fineService.addFine(e.fine); emit(FineActionSuccess()); }
      catch (err) { emit(FineError(err.toString())); }
    });
    on<UpdateFineEvent>((e, emit) async {
      emit(FineLoading());
      try { await fineService.updateFine(e.fine); emit(FineActionSuccess()); }
      catch (err) { emit(FineError(err.toString())); }
    });
    on<DeleteFineEvent>((e, emit) async {
      emit(FineLoading());
      try { await fineService.deleteFine(e.id_fine); emit(FineActionSuccess()); }
      catch (err) { emit(FineError(err.toString())); }
    });
  }
}
