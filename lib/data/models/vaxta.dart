import 'attendance.dart';

class Vaxta {
  String id;
  String workerId;
  List<Attendance> workDays;
  double totalPaid;
  DateTime paymentDate;
  double? loanAmount; // If advances/penalties exceeded salary
  String? loanReason;

  Vaxta({
    required this.id,
    required this.workerId,
    required this.workDays,
    required this.totalPaid,
    required this.paymentDate,
    this.loanAmount,
    this.loanReason,
  });

  factory Vaxta.fromJson(Map<String, dynamic> json) => Vaxta(
        id: json['id'] as String,
        workerId: json['workerId'] as String,
        workDays: json['workDays'] != null
            ? (json['workDays'] as List).map((e) => Attendance.fromJson(e as Map<String, dynamic>)).toList()
            : [],
        totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
        paymentDate: DateTime.parse(json['paymentDate'] as String),
        loanAmount: (json['loanAmount'] as num?)?.toDouble(),
        loanReason: json['loanReason'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'workDays': workDays.map((e) => e.toJson()).toList(),
        'totalPaid': totalPaid,
        'paymentDate': paymentDate.toIso8601String(),
        'loanAmount': loanAmount,
        'loanReason': loanReason,
      };
}
