import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'tool_model.g.dart';

@HiveType(typeId: 0)
class Tool {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String brand;

  @HiveField(4)
  String category;

  @HiveField(5)
  String uniqueId;

  @HiveField(6)
  String? imageUrl;

  @HiveField(7)
  String? localImagePath;

  @HiveField(8)
  bool isFavorite;

  @HiveField(9)
  String? currentProjectId;

  @HiveField(10)
  List<LocationHistory> locationHistory;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  @HiveField(13)
  bool isSynced;

  @HiveField(14)
  String? qrCode;

  Tool({
    String? id,
    required this.title,
    required this.description,
    required this.brand,
    required this.category,
    required this.uniqueId,
    this.imageUrl,
    this.localImagePath,
    this.isFavorite = false,
    this.currentProjectId,
    List<LocationHistory>? locationHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.qrCode,
  })  : id = id ?? const Uuid().v4(),
        locationHistory = locationHistory ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Tool copyWith({
    String? id,
    String? title,
    String? description,
    String? brand,
    String? category,
    String? uniqueId,
    String? imageUrl,
    String? localImagePath,
    bool? isFavorite,
    String? currentProjectId,
    List<LocationHistory>? locationHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? qrCode,
  }) {
    return Tool(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      uniqueId: uniqueId ?? this.uniqueId,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      currentProjectId: currentProjectId ?? this.currentProjectId,
      locationHistory: locationHistory ?? this.locationHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
      qrCode: qrCode ?? this.qrCode,
    );
  }

  Tool duplicate() {
    return Tool(
      title: title,
      description: description,
      brand: brand,
      category: category,
      uniqueId: '${uniqueId}_copy_${DateTime.now().millisecondsSinceEpoch}',
      imageUrl: imageUrl,
      localImagePath: localImagePath,
      isFavorite: false,
    );
  }

  void addLocationHistory(String projectId, String projectName) {
    locationHistory.add(LocationHistory(
      projectId: projectId,
      projectName: projectName,
      movedAt: DateTime.now(),
    ));
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'brand': brand,
      'category': category,
      'uniqueId': uniqueId,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
      'currentProjectId': currentProjectId,
      'locationHistory': locationHistory.map((h) => h.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'qrCode': qrCode,
    };
  }

  static Tool fromJson(Map<String, dynamic> json) {
    return Tool(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      brand: json['brand'],
      category: json['category'],
      uniqueId: json['uniqueId'],
      imageUrl: json['imageUrl'],
      isFavorite: json['isFavorite'] ?? false,
      currentProjectId: json['currentProjectId'],
      locationHistory: (json['locationHistory'] as List?)
              ?.map((h) => LocationHistory.fromJson(h))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      qrCode: json['qrCode'],
    );
  }
}

@HiveType(typeId: 1)
class LocationHistory {
  @HiveField(0)
  final String projectId;

  @HiveField(1)
  final String projectName;

  @HiveField(2)
  final DateTime movedAt;

  LocationHistory({
    required this.projectId,
    required this.projectName,
    required this.movedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'movedAt': movedAt.toIso8601String(),
    };
  }

  static LocationHistory fromJson(Map<String, dynamic> json) {
    return LocationHistory(
      projectId: json['projectId'],
      projectName: json['projectName'],
      movedAt: DateTime.parse(json['movedAt']),
    );
  }
}
