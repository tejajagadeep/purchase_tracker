class PurchaseGroup {
  final String id;
  final String name;
  final String? description;
  final String iconName;
  final double? targetBudget;
  final DateTime createdAt;

  PurchaseGroup({
    required this.id,
    required this.name,
    this.description,
    this.iconName = 'two_wheeler',
    this.targetBudget,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  PurchaseGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    double? targetBudget,
    DateTime? createdAt,
  }) {
    return PurchaseGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      targetBudget: targetBudget ?? this.targetBudget,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'targetBudget': targetBudget,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PurchaseGroup.fromMap(Map<String, dynamic> map) {
    return PurchaseGroup(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      iconName: map['iconName'] ?? 'two_wheeler',
      targetBudget: map['targetBudget'] != null
          ? (map['targetBudget'] as num).toDouble()
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
