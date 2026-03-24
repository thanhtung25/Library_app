import 'package:bloc/bloc.dart';
import '../../api_localhost/NotificationService.dart';
import 'event.dart';
import 'state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService notificationService;
  NotificationBloc(this.notificationService) : super(NotificationInitial()) {
    on<GetAllNotificationsEvent>((e, emit) async {
      emit(NotificationLoading());
      try { emit(NotificationSuccess(await notificationService.getAllNotifications())); }
      catch (err) { emit(NotificationError(err.toString())); }
    });
    on<GetNotificationByIdEvent>((e, emit) async {
      emit(NotificationLoading());
      try { emit(NotificationByIdSuccess(notification: await notificationService.getNotificationById(e.id_notification))); }
      catch (err) { emit(NotificationError(err.toString())); }
    });
    on<AddNotificationEvent>((e, emit) async {
      emit(NotificationLoading());
      try { await notificationService.addNotification(e.notification); emit(NotificationActionSuccess()); }
      catch (err) { emit(NotificationError(err.toString())); }
    });
    on<UpdateNotificationEvent>((e, emit) async {
      emit(NotificationLoading());
      try { await notificationService.updateNotification(e.notification); emit(NotificationActionSuccess()); }
      catch (err) { emit(NotificationError(err.toString())); }
    });
    on<DeleteNotificationEvent>((e, emit) async {
      emit(NotificationLoading());
      try { await notificationService.deleteNotification(e.id_notification); emit(NotificationActionSuccess()); }
      catch (err) { emit(NotificationError(err.toString())); }
    });
  }
}
