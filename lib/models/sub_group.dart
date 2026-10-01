class SubGroup {
  final String id;
  final String groupId;
  final String name;
  final double? targetBudget;
  final bool isPinned;
  final DateTime createdAt;

  SubGroup({
    required this.id,
    required this.groupId,
    required this.name,
    this.targetBudget,
    this.isPinned = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SubGroup copyWith({
    String? id,
    String? groupId,
    String? name,
    double? targetBudget,
    bool? isPinned,
    DateTime? createdAt,
  }) {
    return SubGroup(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      targetBudget: targetBudget ?? this.targetBudget,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'name': name,
      'targetBudget': targetBudget,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SubGroup.fromMap(Map<String, dynamic> map) {
    return SubGroup(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      name: map['name'] ?? '',
      targetBudget: map['targetBudget'] != null
          ? (map['targetBudget'] as num).toDouble()
          : null,
      isPinned: map['isPinned'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
