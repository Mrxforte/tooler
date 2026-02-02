class ProjectModel {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool isActive;
  final List<String> tools;

  ProjectModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.startedAt,
    this.completedAt,
    required this.isActive,
    required this.tools,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      isActive: json['isActive'],
      tools: List<String>.from(json['tools']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isActive': isActive,
      'tools': tools,
    };
  }
}
