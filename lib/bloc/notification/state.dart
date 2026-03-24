import '../../model/notification_model.dart';
abstract class NotificationState {}
class NotificationInitial extends NotificationState {}
class NotificationLoading extends NotificationState {}
class NotificationSuccess extends NotificationState { final List<NotificationModel> notifications; NotificationSuccess(this.notifications); }
class NotificationByIdSuccess extends NotificationState { final NotificationModel notification; NotificationByIdSuccess({required this.notification}); }
class NotificationActionSuccess extends NotificationState {}
class NotificationError extends NotificationState { final String message; NotificationError(this.message); }
