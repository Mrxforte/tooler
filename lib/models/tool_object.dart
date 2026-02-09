class ToolObject {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;

  ToolObject({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ToolObject.fromMap(String id, Map<String, dynamic> map) {
    return ToolObject(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  ToolObject copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return ToolObject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
