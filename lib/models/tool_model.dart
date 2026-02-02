class ToolModel {
  final String name;
  final String imageUrl;
  final String description;
  final String lastProjectId;
  final DateTime addedAt;
  final bool isActive;
  final double price;
  final List<String> projectsHistory;

  ToolModel({
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.lastProjectId,
    required this.addedAt,
    required this.isActive,
    required this.price,
    required this.projectsHistory,
  });
  factory ToolModel.fromJson(Map<String, dynamic> json) {
    return ToolModel(
      name: json['name'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      lastProjectId: json['lastProjectId'],
      addedAt: DateTime.parse(json['addedAt']),
      isActive: json['isActive'],
      price: json['price'].toDouble(),
      projectsHistory: List<String>.from(json['projectsHistory']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'lastProjectId': lastProjectId,
      'addedAt': addedAt.toIso8601String(),
      'isActive': isActive,
      'price': price,
      'projectsHistory': projectsHistory,
    };
  }
}
