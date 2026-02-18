enum RequestType {
  addWorker,
  removeWorker,
  addTool,
  removeTool,
  moveWorker,
  moveTool,
  changeSalary,
  giveBonus,
}

enum RequestStatus { pending, approved, rejected }

class BrigadierRequest {
  final String id;
  final String brigadierId;
  final String objectId;
  final RequestType type;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy; // Admin who approved/rejected
  final Map<String, dynamic> data; // Details of the request (workerId, toolId, etc.)
  final String? reason;
  final String? rejectionReason;

  BrigadierRequest({
    required this.id,
    required this.brigadierId,
    required this.objectId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    required this.data,
    this.reason,
    this.rejectionReason,
  });

  factory BrigadierRequest.fromJson(Map<String, dynamic> json) =>
      BrigadierRequest(
        id: json['id'] as String,
        brigadierId: json['brigadierId'] as String,
        objectId: json['objectId'] as String,
        type: RequestType.values.firstWhere(
          (e) => e.toString().split('.').last == json['type'],
        ),
        status: RequestStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status'],
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'] as String)
            : null,
        resolvedBy: json['resolvedBy'] as String?,
        data: Map<String, dynamic>.from(json['data'] as Map),
        reason: json['reason'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'brigadierId': brigadierId,
        'objectId': objectId,
        'type': type.toString().split('.').last,
        'status': status.toString().split('.').last,
        'createdAt': createdAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
        'resolvedBy': resolvedBy,
        'data': data,
        'reason': reason,
        'rejectionReason': rejectionReason,
      };
}
