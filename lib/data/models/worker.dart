class Worker {
  String id;
  String email;
  String name;
  String? nickname;
  String? phone;
  String? assignedObjectId;
  String role;
  double hourlyRate;
  double dailyRate;
  double totalBonus; // Total bonuses earned
  double monthlyBonus; // Monthly bonus allowance
  DateTime createdAt;
  bool isFavorite;
  bool isSelected;

  Worker({
    required this.id,
    required this.email,
    required this.name,
    this.nickname,
    this.phone,
    this.assignedObjectId,
    this.role = 'worker',
    this.hourlyRate = 0.0,
    this.dailyRate = 0.0,
    this.totalBonus = 0.0,
    this.monthlyBonus = 0.0,
    DateTime? createdAt,
    this.isFavorite = false,
    this.isSelected = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        nickname: json['nickname'] as String?,
        phone: json['phone'] as String?,
        assignedObjectId: json['assignedObjectId'] as String?,
        role: json['role'] as String? ?? 'worker',
        hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
        dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
        totalBonus: (json['totalBonus'] as num?)?.toDouble() ?? 0.0,
        monthlyBonus: (json['monthlyBonus'] as num?)?.toDouble() ?? 0.0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        isFavorite: json['isFavorite'] as bool? ?? false,
        isSelected: json['isSelected'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'nickname': nickname,
        'phone': phone,
        'assignedObjectId': assignedObjectId,
        'role': role,
        'hourlyRate': hourlyRate,
        'dailyRate': dailyRate,
        'totalBonus': totalBonus,
        'monthlyBonus': monthlyBonus,
        'createdAt': createdAt.toIso8601String(),
        'isFavorite': isFavorite,
        'isSelected': isSelected,
      };

  Worker copyWith({
    String? id,
    String? email,
    String? name,
    String? nickname,
    String? phone,
    String? assignedObjectId,
    String? role,
    double? hourlyRate,
    double? dailyRate,
    double? totalBonus,
    double? monthlyBonus,
    DateTime? createdAt,
    bool? isFavorite,
    bool? isSelected,
  }) {
    return Worker(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      phone: phone ?? this.phone,
      assignedObjectId: assignedObjectId ?? this.assignedObjectId,
      role: role ?? this.role,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      dailyRate: dailyRate ?? this.dailyRate,
      totalBonus: totalBonus ?? this.totalBonus,
      monthlyBonus: monthlyBonus ?? this.monthlyBonus,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
