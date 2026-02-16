class BonusEntry {
  final String id;
  final String workerId;
  final double amount;
  final String reason;
  final DateTime date;
  final String givenBy; // Admin or Brigadier who gave the bonus
  final String? notes;

  BonusEntry({
    required this.id,
    required this.workerId,
    required this.amount,
    required this.reason,
    required this.date,
    required this.givenBy,
    this.notes,
  });

  factory BonusEntry.fromJson(Map<String, dynamic> json) => BonusEntry(
        id: json['id'] as String,
        workerId: json['workerId'] as String,
        amount: (json['amount'] as num).toDouble(),
        reason: json['reason'] as String,
        date: DateTime.parse(json['date'] as String),
        givenBy: json['givenBy'] as String,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'amount': amount,
        'reason': reason,
        'date': date.toIso8601String(),
        'givenBy': givenBy,
        'notes': notes,
      };
}
