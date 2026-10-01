class PurchaseGroup {
  final String id;
  final String name;
  final String? description;
  final String iconName;
  final DateTime createdAt;

  PurchaseGroup({
    required this.id,
    required this.name,
    this.description,
    this.iconName = 'two_wheeler',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PurchaseGroup.fromMap(Map<String, dynamic> map) {
    return PurchaseGroup(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      iconName: map['iconName'] ?? 'two_wheeler',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
