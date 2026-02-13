import 'location_history.dart';

class Tool {
  String id;
  String title;
  String description;
  String brand;
  String uniqueId;
  String? imageUrl;
  String? localImagePath;
  String currentLocation; // 'garage' or objectId
  String currentLocationName; // For display purposes
  List<LocationHistory> locationHistory;
  bool isFavorite;
  DateTime createdAt;
  DateTime updatedAt;
  bool isSelected;
  String userId;

  Tool({
    required this.id,
    required this.title,
    required this.description,
    required this.brand,
    required this.uniqueId,
    this.imageUrl,
    this.localImagePath,
    required this.currentLocation,
    required this.currentLocationName,
    List<LocationHistory>? locationHistory,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSelected = false,
    required this.userId,
  }) : locationHistory = locationHistory ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Tool.fromJson(Map<String, dynamic> json) => Tool(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    brand: json['brand'] as String,
    uniqueId: json['uniqueId'] as String,
    imageUrl: json['imageUrl'] as String?,
    localImagePath: json['localImagePath'] as String?,
    currentLocation: json['currentLocation'] as String? ?? 'garage',
    currentLocationName: json['currentLocationName'] as String? ?? 'Гараж',
    locationHistory:
        (json['locationHistory'] as List?)
            ?.map((e) => LocationHistory.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [],
    isFavorite: json['isFavorite'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.now(),
    isSelected: json['isSelected'] as bool? ?? false,
    userId: json['userId'] as String? ?? 'unknown',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'brand': brand,
    'uniqueId': uniqueId,
    'imageUrl': imageUrl,
    'localImagePath': localImagePath,
    'currentLocation': currentLocation,
    'currentLocationName': currentLocationName,
    'locationHistory': locationHistory.map((e) => e.toJson()).toList(),
    'isFavorite': isFavorite,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isSelected': isSelected,
    'userId': userId,
  };

  Tool copyWith({
    String? id,
    String? title,
    String? description,
    String? brand,
    String? uniqueId,
    String? imageUrl,
    String? localImagePath,
    String? currentLocation,
    String? currentLocationName,
    List<LocationHistory>? locationHistory,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSelected,
    String? userId,
  }) {
    return Tool(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      uniqueId: uniqueId ?? this.uniqueId,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      currentLocation: currentLocation ?? this.currentLocation,
      currentLocationName: currentLocationName ?? this.currentLocationName,
      locationHistory: locationHistory ?? this.locationHistory,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSelected: isSelected ?? this.isSelected,
      userId: userId ?? this.userId,
    );
  }

  Tool duplicate(int copyNumber) => Tool(
    id: '${DateTime.now().millisecondsSinceEpoch}',
    title: '$title (Копия ${copyNumber > 1 ? copyNumber : ''})'.trim(),
    description: description,
    brand: brand,
    uniqueId: '${uniqueId}_copy_$copyNumber',
    imageUrl: imageUrl,
    localImagePath: localImagePath,
    currentLocation: currentLocation,
    currentLocationName: currentLocationName,
    locationHistory: List.from(locationHistory),
    isFavorite: isFavorite,
    userId: userId,
  );

  String? get displayImage {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      return localImagePath;
    }
    return null;
  }
}
