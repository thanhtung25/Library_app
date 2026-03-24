import 'package:equatable/equatable.dart';

import '../../model/reservations_model.dart';

abstract class ReservationEvent extends Equatable {
  const ReservationEvent();

  @override
  List<Object?> get props => [];
}

class GetReservationsEvent extends ReservationEvent {
  const GetReservationsEvent();
}

class GetReservationsByUserEvent extends ReservationEvent {
  final int idUser;

  const GetReservationsByUserEvent(this.idUser);

  @override
  List<Object?> get props => [idUser];
}

class GetReservationsByBookEvent extends ReservationEvent {
  final int idBook;

  const GetReservationsByBookEvent(this.idBook);

  @override
  List<Object?> get props => [idBook];
}

class AddReservationEvent extends ReservationEvent {
  final ReservationModel reservation;

  const AddReservationEvent(this.reservation);

  @override
  List<Object?> get props => [reservation];
}

class UpdateReservationEvent extends ReservationEvent {
  final ReservationModel reservation;

  const UpdateReservationEvent(this.reservation);

  @override
  List<Object?> get props => [reservation];
}

class DeleteReservationEvent extends ReservationEvent {
  final int idReservation;

  const DeleteReservationEvent(this.idReservation);

  @override
  List<Object?> get props => [idReservation];
}

class ClearReservationEvent extends ReservationEvent {
  const ClearReservationEvent();
}