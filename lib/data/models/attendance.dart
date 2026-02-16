class Attendance {
  String id;
  String workerId;
  DateTime date;
  bool present;
  double hoursWorked;
  String? notes;

  Attendance({
    required this.id,
    required this.workerId,
    required this.date,
    required this.present,
    this.hoursWorked = 0,
    this.notes,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json['id'] as String,
        workerId: json['workerId'] as String,
        date: DateTime.parse(json['date'] as String),
        present: json['present'] as bool,
        hoursWorked: (json['hoursWorked'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'date': date.toIso8601String(),
        'present': present,
        'hoursWorked': hoursWorked,
        'notes': notes,
      };
}

class DailyWorkReport {
  String id;
  String objectId;
  String brigadierId;
  DateTime date;
  List<String> attendanceIds;
  String status;
  DateTime submittedAt;

  DailyWorkReport({
    required this.id,
    required this.objectId,
    required this.brigadierId,
    required this.date,
    required this.attendanceIds,
    this.status = 'pending',
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();

  factory DailyWorkReport.fromJson(Map<String, dynamic> json) =>
      DailyWorkReport(
        id: json['id'] as String,
        objectId: json['objectId'] as String,
        brigadierId: json['brigadierId'] as String,
        date: DateTime.parse(json['date'] as String),
        attendanceIds: List<String>.from(json['attendanceIds']),
        status: json['status'] as String? ?? 'pending',
        submittedAt: DateTime.parse(json['submittedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'objectId': objectId,
        'brigadierId': brigadierId,
        'date': date.toIso8601String(),
        'attendanceIds': attendanceIds,
        'status': status,
        'submittedAt': submittedAt.toIso8601String(),
      };
}
