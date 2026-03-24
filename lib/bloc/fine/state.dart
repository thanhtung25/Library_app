import '../../model/fine_model.dart';
abstract class FineState {}
class FineInitial extends FineState {}
class FineLoading extends FineState {}
class FineSuccess extends FineState { final List<FineModel> fines; FineSuccess(this.fines); }
class FineByIdSuccess extends FineState { final FineModel fine; FineByIdSuccess({required this.fine}); }
class FineActionSuccess extends FineState {}
class FineError extends FineState { final String message; FineError(this.message); }
