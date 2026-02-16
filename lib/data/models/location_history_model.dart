enum WorkerLocation { home, object, garage }

enum ToolLocation { home, object, garage }

class LocationHistoryEntry {
  final String id;
  final String resourceId; // Worker or Tool ID
  final String resourceType; // 'worker' or 'tool'
  final String fromLocation;
  final String toLocation;
  final DateTime date;
  final String? movedBy; // Admin or Brigadier who moved it
  final String? reason;
  final String? objectId; // If moved to/from an object

  LocationHistoryEntry({
    required this.id,
    required this.resourceId,
    required this.resourceType,
    required this.fromLocation,
    required this.toLocation,
    required this.date,
    this.movedBy,
    this.reason,
    this.objectId,
  });

  factory LocationHistoryEntry.fromJson(Map<String, dynamic> json) =>
      LocationHistoryEntry(
        id: json['id'] as String,
        resourceId: json['resourceId'] as String,
        resourceType: json['resourceType'] as String,
        fromLocation: json['fromLocation'] as String,
        toLocation: json['toLocation'] as String,
        date: DateTime.parse(json['date'] as String),
        movedBy: json['movedBy'] as String?,
        reason: json['reason'] as String?,
        objectId: json['objectId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'resourceId': resourceId,
        'resourceType': resourceType,
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'date': date.toIso8601String(),
        'movedBy': movedBy,
        'reason': reason,
        'objectId': objectId,
      };
}
