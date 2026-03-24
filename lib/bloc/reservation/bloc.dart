import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/reservation/event.dart';
import 'package:library_app/bloc/reservation/state.dart';

import '../../api_localhost/reservation_service.dart';
import '../../model/reservations_model.dart';

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final ReservationService reservationService;

  ReservationBloc(this.reservationService) : super(const ReservationInitial()) {
    on<GetReservationsEvent>(_onGetReservations);
    on<GetReservationsByUserEvent>(_onGetReservationsByUser);
    on<AddReservationEvent>(_onAddReservation);
    on<UpdateReservationEvent>(_onUpdateReservation);
    on<DeleteReservationEvent>(_onDeleteReservation);
    on<ClearReservationEvent>(_onClearReservation);
  }

  Future<void> _onGetReservations(
      GetReservationsEvent event,
      Emitter<ReservationState> emit,
      ) async {
    emit(const ReservationLoading());
    try {
      final List<ReservationModel> reservations =
      await reservationService.getReservations();
      emit(ReservationLoaded(reservations));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onGetReservationsByUser(
      GetReservationsByUserEvent event,
      Emitter<ReservationState> emit,
      ) async {
    emit(const ReservationLoading());
    try {
      final List<ReservationModel> reservations =
      await reservationService.getReservationsByUser(event.idUser);
      emit(ReservationLoaded(reservations));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }


  Future<void> _onAddReservation(
      AddReservationEvent event,
      Emitter<ReservationState> emit,
      ) async {
    emit(const ReservationLoading());
    try {
      final ReservationModel created =
      await reservationService.addReservation(event.reservation);
      emit(ReservationCreated(created));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onUpdateReservation(
      UpdateReservationEvent event,
      Emitter<ReservationState> emit,
      ) async {
    emit(const ReservationLoading());
    try {
      final ReservationModel updated =
      await reservationService.updateReservation(event.reservation);
      emit(ReservationUpdated(updated));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onDeleteReservation(
      DeleteReservationEvent event,
      Emitter<ReservationState> emit,
      ) async {
    emit(const ReservationLoading());
    try {
      await reservationService.deleteReservation(event.idReservation);
      emit(const ReservationDeleted());
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  void _onClearReservation(
      ClearReservationEvent event,
      Emitter<ReservationState> emit,
      ) {
    emit(const ReservationInitial());
  }
}