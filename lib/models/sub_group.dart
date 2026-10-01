class SubGroup {
  final String id;
  final String groupId;
  final String name;
  final DateTime createdAt;

  SubGroup({
    required this.id,
    required this.groupId,
    required this.name,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SubGroup.fromMap(Map<String, dynamic> map) {
    return SubGroup(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      name: map['name'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
