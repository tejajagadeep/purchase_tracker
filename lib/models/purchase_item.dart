class PurchaseItem {
  final String id;
  final String groupId;
  final String name;
  final int quantity;
  final double plannedPrice;
  final double? actualPrice;
  final String category;
  final List<DateTime> purchaseDates;
  final String? notes;

  PurchaseItem({
    required this.id,
    this.groupId = 'bike_touring',
    required this.name,
    this.quantity = 1,
    required this.plannedPrice,
    this.actualPrice,
    required this.category,
    List<DateTime>? purchaseDates,
    bool? isPurchased,
    DateTime? datePurchased,
    this.notes,
  }) : purchaseDates = purchaseDates ??
            ((isPurchased == true || datePurchased != null)
                ? List.generate(
                    quantity,
                    (_) => datePurchased ?? DateTime.now(),
                  )
                : []);

  bool get isPurchased => purchaseDates.length >= quantity;

  int get purchasedQuantity => purchaseDates.length;

  DateTime? get datePurchased =>
      purchaseDates.isNotEmpty ? purchaseDates.last : null;

  double get plannedTotal => quantity * plannedPrice;

  double get actualTotal =>
      purchasedQuantity * (actualPrice ?? plannedPrice);

  double get effectiveTotal =>
      purchasedQuantity > 0 ? actualTotal : plannedTotal;

  PurchaseItem copyWith({
    String? id,
    String? groupId,
    String? name,
    int? quantity,
    double? plannedPrice,
    double? actualPrice,
    String? category,
    List<DateTime>? purchaseDates,
    bool? isPurchased,
    DateTime? datePurchased,
    String? notes,
  }) {
    List<DateTime>? updatedDates = purchaseDates;
    if (updatedDates == null && (isPurchased != null || datePurchased != null)) {
      final targetPurchased = isPurchased ?? this.isPurchased;
      final targetDate = datePurchased ?? this.datePurchased ?? DateTime.now();
      final targetQty = quantity ?? this.quantity;
      updatedDates = targetPurchased
          ? List.generate(targetQty, (_) => targetDate)
          : [];
    }

    return PurchaseItem(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      plannedPrice: plannedPrice ?? this.plannedPrice,
      actualPrice: actualPrice ?? this.actualPrice,
      category: category ?? this.category,
      purchaseDates: updatedDates ?? this.purchaseDates,
      notes: notes ?? this.notes,
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
      'purchaseDates': purchaseDates.map((d) => d.toIso8601String()).toList(),
      'isPurchased': isPurchased,
      'notes': notes,
      'datePurchased': datePurchased?.toIso8601String(),
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    final qty = map['quantity'] ?? 1;
    List<DateTime> dates = [];

    if (map['purchaseDates'] != null) {
      final List<dynamic> list = map['purchaseDates'];
      dates = list
          .map((e) => DateTime.tryParse(e.toString()))
          .whereType<DateTime>()
          .toList();
    } else if (map['isPurchased'] == true || map['datePurchased'] != null) {
      final d = map['datePurchased'] != null
          ? DateTime.tryParse(map['datePurchased'])
          : DateTime.now();
      if (d != null) {
        dates = List.generate(qty, (_) => d);
      }
    }

    return PurchaseItem(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? 'bike_touring',
      name: map['name'] ?? '',
      quantity: qty,
      plannedPrice: (map['plannedPrice'] as num).toDouble(),
      actualPrice: map['actualPrice'] != null
          ? (map['actualPrice'] as num).toDouble()
          : null,
      category: map['category'] ?? 'Other',
      purchaseDates: dates,
      notes: map['notes'],
    );
  }
}
