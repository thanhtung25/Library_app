class NotificationModel {
  final int? id_notification;
  final int id_user;
  final String type;
  final String message;
  final DateTime? sent_at;
  final bool is_read;

  NotificationModel({
    this.id_notification, required this.id_user,
    required this.type, required this.message,
    this.sent_at, this.is_read = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id_notification: json['id_notification'],
      id_user: json['id_user'] ?? 0,
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      sent_at: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString()) : null,
      is_read: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_notification': id_notification, 'id_user': id_user,
      'type': type, 'message': message,
      'sent_at': sent_at?.toIso8601String(), 'is_read': is_read,
    };
  }

  NotificationModel copyWith({
    int? id_notification, int? id_user, String? type,
    String? message, DateTime? sent_at, bool? is_read,
  }) {
    return NotificationModel(
      id_notification: id_notification ?? this.id_notification,
      id_user: id_user ?? this.id_user, type: type ?? this.type,
      message: message ?? this.message, sent_at: sent_at ?? this.sent_at,
      is_read: is_read ?? this.is_read,
    );
  }
}
