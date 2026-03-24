import '../../model/notification_model.dart';
abstract class NotificationEvent {}
class GetAllNotificationsEvent extends NotificationEvent {}
class GetNotificationByIdEvent extends NotificationEvent { final int id_notification; GetNotificationByIdEvent({required this.id_notification}); }
class AddNotificationEvent extends NotificationEvent { final NotificationModel notification; AddNotificationEvent({required this.notification}); }
class UpdateNotificationEvent extends NotificationEvent { final NotificationModel notification; UpdateNotificationEvent({required this.notification}); }
class DeleteNotificationEvent extends NotificationEvent { final int id_notification; DeleteNotificationEvent({required this.id_notification}); }
