class SalaryEntry {
  String id;
  String workerId;
  DateTime date;
  double hoursWorked;
  double amount;
  double bonus;
  String? notes;

  SalaryEntry({
    required this.id,
    required this.workerId,
    required this.date,
    this.hoursWorked = 0,
    this.amount = 0,
    this.bonus = 0,
    this.notes,
  });

  factory SalaryEntry.fromJson(Map<String, dynamic> json) => SalaryEntry(
        id: json['id'] as String,
        workerId: json['workerId'] as String,
        date: DateTime.parse(json['date'] as String),
        hoursWorked: (json['hoursWorked'] as num?)?.toDouble() ?? 0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        bonus: (json['bonus'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'date': date.toIso8601String(),
        'hoursWorked': hoursWorked,
        'amount': amount,
        'bonus': bonus,
        'notes': notes,
      };
}

class Advance {
  String id;
  String workerId;
  DateTime date;
  double amount;
  String? reason;
  bool repaid;

  Advance({
    required this.id,
    required this.workerId,
    required this.date,
    required this.amount,
    this.reason,
    this.repaid = false,
  });

  factory Advance.fromJson(Map<String, dynamic> json) => Advance(
        id: json['id'] as String,
        workerId: json['workerId'] as String,
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        reason: json['reason'] as String?,
        repaid: json['repaid'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'date': date.toIso8601String(),
        'amount': amount,
        'reason': reason,
        'repaid': repaid,
      };
}

class Penalty {
  String id;
  String workerId;
  DateTime date;
  double amount;
  String? reason;

  Penalty({
    required this.id,
    required this.workerId,
    required this.date,
    required this.amount,
    this.reason,
  });

  factory Penalty.fromJson(Map<String, dynamic> json) => Penalty(
        id: json['id'] as String,
        workerId: json['workerId'] as String,
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        reason: json['reason'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'date': date.toIso8601String(),
        'amount': amount,
        'reason': reason,
      };
}
