class Attendance {
  String id;
  String workerId;
  String? objectId;
  DateTime date;
  bool present;
  double hoursWorked;
  double dayFraction;
  double extraHours;
  String? notes;

  Attendance({
    required this.id,
    required this.workerId,
    this.objectId,
    required this.date,
    required this.present,
    this.hoursWorked = 0,
    this.dayFraction = 0,
    this.extraHours = 0,
    this.notes,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json['id'] as String,
        workerId: json['workerId'] as String,
      objectId: json['objectId'] as String?,
        date: DateTime.parse(json['date'] as String),
        present: json['present'] as bool,
        hoursWorked: (json['hoursWorked'] as num?)?.toDouble() ?? 0,
      dayFraction: (json['dayFraction'] as num?)?.toDouble() ?? 0,
      extraHours: (json['extraHours'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
      'objectId': objectId,
        'date': date.toIso8601String(),
        'present': present,
        'hoursWorked': hoursWorked,
      'dayFraction': dayFraction,
      'extraHours': extraHours,
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
        attendanceIds: (json['attendanceIds'] as List).map((e) => e.toString()).toList(),
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
