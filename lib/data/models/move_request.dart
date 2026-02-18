class MoveRequest {
  String id;
  String toolId;
  String fromLocationId;
  String fromLocationName;
  String toLocationId;
  String toLocationName;
  String requestedBy;
  String status;
  DateTime timestamp;

  MoveRequest({
    required this.id,
    required this.toolId,
    required this.fromLocationId,
    required this.fromLocationName,
    required this.toLocationId,
    required this.toLocationName,
    required this.requestedBy,
    required this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolId': toolId,
        'fromLocationId': fromLocationId,
        'fromLocationName': fromLocationName,
        'toLocationId': toLocationId,
        'toLocationName': toLocationName,
        'requestedBy': requestedBy,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MoveRequest.fromJson(Map<String, dynamic> json) => MoveRequest(
        id: json['id'] as String,
        toolId: json['toolId'] as String,
        fromLocationId: json['fromLocationId'] as String,
        fromLocationName: json['fromLocationName'] as String,
        toLocationId: json['toLocationId'] as String,
        toLocationName: json['toLocationName'] as String,
        requestedBy: json['requestedBy'] as String,
        status: json['status'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class BatchMoveRequest {
  String id;
  List<String> toolIds;
  String fromLocationId;
  String fromLocationName;
  String toLocationId;
  String toLocationName;
  String requestedBy;
  String status;
  DateTime timestamp;

  BatchMoveRequest({
    required this.id,
    required this.toolIds,
    required this.fromLocationId,
    required this.fromLocationName,
    required this.toLocationId,
    required this.toLocationName,
    required this.requestedBy,
    required this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolIds': toolIds,
        'fromLocationId': fromLocationId,
        'fromLocationName': fromLocationName,
        'toLocationId': toLocationId,
        'toLocationName': toLocationName,
        'requestedBy': requestedBy,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BatchMoveRequest.fromJson(Map<String, dynamic> json) =>
      BatchMoveRequest(
        id: json['id'] as String,
        toolIds: (json['toolIds'] as List).map((e) => e.toString()).toList(),
        fromLocationId: json['fromLocationId'] as String,
        fromLocationName: json['fromLocationName'] as String,
        toLocationId: json['toLocationId'] as String,
        toLocationName: json['toLocationName'] as String,
        requestedBy: json['requestedBy'] as String,
        status: json['status'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
