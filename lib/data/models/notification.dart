class AppNotification {
  String id;
  String title;
  String body;
  String type;
  String? relatedId;
  String userId;
  bool read;
  DateTime timestamp;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.userId,
    this.read = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'userId': userId,
        'read': read,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        relatedId: json['relatedId'] as String?,
        userId: json['userId'] as String,
        read: json['read'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    String? relatedId,
    String? userId,
    bool? read,
    DateTime? timestamp,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      userId: userId ?? this.userId,
      read: read ?? this.read,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
