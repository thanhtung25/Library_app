
import '../model/reservations_model.dart';
import 'ApiService.dart';

class ReservationService {
  Future<List<ReservationModel>> getReservations() async {
    final response = await ApiService.get('/reservations-management/reservations');
    return (response as List)
        .map((e) => ReservationModel.fromJson(e))
        .toList();
  }

  Future<List<ReservationModel>> getReservationsByUser(int id_user) async {
    final response = await ApiService.get('/reservations/user/$id_user');
    return (response as List)
        .map((e) => ReservationModel.fromJson(e))
        .toList();
  }

  Future<ReservationModel> addReservation(ReservationModel reservation) async {
    final response = await ApiService.post(
      '/reservations-management/reservation',
      reservation.toJson(),
    );
    return ReservationModel.fromJson(response);
  }

  Future<ReservationModel> updateReservation(ReservationModel reservation) async {
    final response = await ApiService.put(
      '/reservations-management/reservation/${reservation.id_reservation}',
      reservation.toJson(),
    );
    return ReservationModel.fromJson(response);
  }

  Future<void> deleteReservation(int id_reservation) async {
    await ApiService.delete('/reservations-management/reservation/$id_reservation');
  }
}