import '../../model/fine_model.dart';
abstract class FineEvent {}
class GetAllFinesEvent extends FineEvent {}
class GetFineByIdEvent extends FineEvent { final int id_fine; GetFineByIdEvent({required this.id_fine}); }
class AddFineEvent extends FineEvent { final FineModel fine; AddFineEvent({required this.fine}); }
class UpdateFineEvent extends FineEvent { final FineModel fine; UpdateFineEvent({required this.fine}); }
class DeleteFineEvent extends FineEvent { final int id_fine; DeleteFineEvent({required this.id_fine}); }
