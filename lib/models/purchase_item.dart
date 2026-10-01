class PurchaseItem {
  final String id;
  final String groupId;
  final String name;
  final int quantity;
  final double plannedPrice;
  final double? actualPrice;
  final String category;
  final bool isPurchased;
  final String? notes;
  final DateTime? datePurchased;

  PurchaseItem({
    required this.id,
    this.groupId = 'bike_touring',
    required this.name,
    this.quantity = 1,
    required this.plannedPrice,
    this.actualPrice,
    required this.category,
    this.isPurchased = false,
    this.notes,
    this.datePurchased,
  });

  double get plannedTotal => quantity * plannedPrice;

  double get actualTotal =>
      quantity * (actualPrice ?? plannedPrice);

  double get effectiveTotal => isPurchased ? actualTotal : plannedTotal;

  PurchaseItem copyWith({
    String? id,
    String? groupId,
    String? name,
    int? quantity,
    double? plannedPrice,
    double? actualPrice,
    String? category,
    bool? isPurchased,
    String? notes,
    DateTime? datePurchased,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      plannedPrice: plannedPrice ?? this.plannedPrice,
      actualPrice: actualPrice ?? this.actualPrice,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
      notes: notes ?? this.notes,
      datePurchased: datePurchased ?? this.datePurchased,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'name': name,
      'quantity': quantity,
      'plannedPrice': plannedPrice,
      'actualPrice': actualPrice,
      'category': category,
      'isPurchased': isPurchased,
      'notes': notes,
      'datePurchased': datePurchased?.toIso8601String(),
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? 'bike_touring',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 1,
      plannedPrice: (map['plannedPrice'] as num).toDouble(),
      actualPrice: map['actualPrice'] != null
          ? (map['actualPrice'] as num).toDouble()
          : null,
      category: map['category'] ?? 'Other',
      isPurchased: map['isPurchased'] ?? false,
      notes: map['notes'],
      datePurchased: map['datePurchased'] != null
          ? DateTime.tryParse(map['datePurchased'])
          : null,
    );
  }
}
