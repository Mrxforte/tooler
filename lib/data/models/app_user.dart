import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String role;
  final bool canMoveTools;
  final bool canControlObjects;
  final DateTime createdAt;
  final bool isSelected;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.canMoveTools = false,
    this.canControlObjects = false,
    this.isSelected = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      canMoveTools: data['canMoveTools'] ?? false,
      canControlObjects: data['canControlObjects'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'role': role,
        'canMoveTools': canMoveTools,
        'canControlObjects': canControlObjects,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  AppUser copyWith({
    String? uid,
    String? email,
    String? role,
    bool? canMoveTools,
    bool? canControlObjects,
    bool? isSelected,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      canMoveTools: canMoveTools ?? this.canMoveTools,
      canControlObjects: canControlObjects ?? this.canControlObjects,
      isSelected: isSelected ?? this.isSelected,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
