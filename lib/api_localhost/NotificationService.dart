import '../model/notification_model.dart';
import 'ApiService.dart';

class NotificationService {
  Future<List<NotificationModel>> getAllNotifications() async {
    final data = await ApiService.get('/notifications-management/notifications');
    return (data as List).map((e) => NotificationModel.fromJson(e)).toList();
  }

  Future<NotificationModel> getNotificationById(int id_notification) async {
    final data = await ApiService.get('/notifications-management/notification/$id_notification');
    return NotificationModel.fromJson(data);
  }

  Future<NotificationModel> addNotification(NotificationModel notification) async {
    final data = await ApiService.post(
        '/notifications-management/notification', notification.toJson());
    return NotificationModel.fromJson(data);
  }

  Future<NotificationModel> updateNotification(NotificationModel notification) async {
    final data = await ApiService.put(
        '/notifications-management/notification/${notification.id_notification}',
        notification.toJson());
    return NotificationModel.fromJson(data);
  }

  Future<void> deleteNotification(int id_notification) async {
    await ApiService.delete('/notifications-management/notification/$id_notification');
  }
}
