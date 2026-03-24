import 'package:equatable/equatable.dart';

import '../../model/reservations_model.dart';

abstract class ReservationState extends Equatable {
  const ReservationState();

  @override
  List<Object?> get props => [];
}

class ReservationInitial extends ReservationState {
  const ReservationInitial();
}

class ReservationLoading extends ReservationState {
  const ReservationLoading();
}

class ReservationLoaded extends ReservationState {
  final List<ReservationModel> reservations;

  const ReservationLoaded(this.reservations);

  @override
  List<Object?> get props => [reservations];
}

class ReservationCreated extends ReservationState {
  final ReservationModel reservation;
  final String message;

  const ReservationCreated(this.reservation, {this.message = 'Reservation created successfully'});

  @override
  List<Object?> get props => [reservation, message];
}

class ReservationUpdated extends ReservationState {
  final ReservationModel reservation;
  final String message;

  const ReservationUpdated(this.reservation, {this.message = 'Reservation updated successfully'});

  @override
  List<Object?> get props => [reservation, message];
}

class ReservationDeleted extends ReservationState {
  final String message;

  const ReservationDeleted({this.message = 'Reservation deleted successfully'});

  @override
  List<Object?> get props => [message];
}

class ReservationError extends ReservationState {
  final String error;

  const ReservationError(this.error);

  @override
  List<Object?> get props => [error];
}