class Worker {
  String id;
  String email;
  String name;
  String? nickname;
  String? phone;
  List<String> assignedObjectIds;
  String role;
  double hourlyRate; // Required field for salary calculation
  double dailyRate;
  double totalBonus; // Total bonuses earned
  double monthlyBonus; // Monthly bonus allowance
  DateTime createdAt;
  bool isFavorite;
  bool isSelected;
  List<Map<String, dynamic>> vaxtas; // Work history records (payment periods)

  Worker({
    required this.id,
    required this.email,
    required this.name,
    this.nickname,
    this.phone,
    List<String>? assignedObjectIds,
    this.role = 'worker',
    required this.hourlyRate, // Now required
    this.dailyRate = 0.0,
    this.totalBonus = 0.0,
    this.monthlyBonus = 0.0,
    DateTime? createdAt,
    this.isFavorite = false,
    this.isSelected = false,
    List<Map<String, dynamic>>? vaxtas,
  })  : assignedObjectIds = assignedObjectIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        vaxtas = vaxtas ?? [];

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        nickname: json['nickname'] as String?,
        phone: json['phone'] as String?,
        assignedObjectIds: json['assignedObjectIds'] != null
            ? List<String>.from(json['assignedObjectIds'] as List)
            : json['assignedObjectId'] != null
              ? [json['assignedObjectId'] as String]
              : <String>[],
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
        vaxtas: json['vaxtas'] != null 
            ? (json['vaxtas'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'nickname': nickname,
        'phone': phone,
        'assignedObjectIds': assignedObjectIds,
        'role': role,
        'hourlyRate': hourlyRate,
        'dailyRate': dailyRate,
        'totalBonus': totalBonus,
        'monthlyBonus': monthlyBonus,
        'createdAt': createdAt.toIso8601String(),
        'isFavorite': isFavorite,
        'isSelected': isSelected,
        'vaxtas': vaxtas,
      };

  Worker copyWith({
    String? id,
    String? email,
    String? name,
    String? nickname,
    String? phone,
    List<String>? assignedObjectIds,
    String? role,
    double? hourlyRate,
    double? dailyRate,
    double? totalBonus,
    double? monthlyBonus,
    DateTime? createdAt,
    bool? isFavorite,
    bool? isSelected,
    List<Map<String, dynamic>>? vaxtas,
  }) {
    return Worker(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      phone: phone ?? this.phone,
      assignedObjectIds: assignedObjectIds ?? this.assignedObjectIds,
      role: role ?? this.role,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      dailyRate: dailyRate ?? this.dailyRate,
      totalBonus: totalBonus ?? this.totalBonus,
      monthlyBonus: monthlyBonus ?? this.monthlyBonus,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isSelected: isSelected ?? this.isSelected,
      vaxtas: vaxtas ?? this.vaxtas,
    );
  }
}
