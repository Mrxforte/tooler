class ConstructionObject {
  String id;
  String name;
  String description;
  String? imageUrl;
  String? localImagePath;
  List<String> toolIds;
  DateTime createdAt;
  DateTime updatedAt;
  bool isSelected;
  String userId;

  ConstructionObject({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.localImagePath,
    List<String>? toolIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSelected = false,
    required this.userId,
  }) : toolIds = toolIds ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ConstructionObject.fromJson(Map<String, dynamic> json) =>
      ConstructionObject(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        imageUrl: json['imageUrl'] as String?,
        localImagePath: json['localImagePath'] as String?,
        toolIds: List<String>.from(json['toolIds'] ?? []),
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
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'localImagePath': localImagePath,
    'toolIds': toolIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isSelected': isSelected,
    'userId': userId,
  };

  ConstructionObject copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? localImagePath,
    List<String>? toolIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSelected,
    String? userId,
  }) {
    return ConstructionObject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      toolIds: toolIds ?? this.toolIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSelected: isSelected ?? this.isSelected,
      userId: userId ?? this.userId,
    );
  }

  String? get displayImage {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    if (localImagePath != null && localImagePath!.isNotEmpty) {
      return localImagePath;
    }
    return null;
  }
}
