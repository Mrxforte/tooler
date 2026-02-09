class Tool {
  final String id;
  final String objectId;
  final String name;
  final String description;
  final int quantity;
  final DateTime createdAt;

  Tool({
    required this.id,
    required this.objectId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'objectId': objectId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Tool.fromMap(String id, Map<String, dynamic> map) {
    return Tool(
      id: id,
      objectId: map['objectId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Tool copyWith({
    String? id,
    String? objectId,
    String? name,
    String? description,
    int? quantity,
    DateTime? createdAt,
  }) {
    return Tool(
      id: id ?? this.id,
      objectId: objectId ?? this.objectId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
