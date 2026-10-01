class PurchaseItem {
  final String id;
  final String groupId;
  final String? subGroupId;
  final String name;
  final int quantity;
  final double plannedPrice;
  final double? actualPrice;
  final List<double?> unitActualPrices;
  final String category;
  final List<DateTime> purchaseDates;
  final String? notes;

  PurchaseItem({
    required this.id,
    this.groupId = 'bike_touring',
    this.subGroupId,
    required this.name,
    this.quantity = 1,
    required this.plannedPrice,
    this.actualPrice,
    List<double?>? unitActualPrices,
    required this.category,
    List<DateTime>? purchaseDates,
    bool? isPurchased,
    DateTime? datePurchased,
    this.notes,
  })  : unitActualPrices = unitActualPrices ?? [],
        purchaseDates = purchaseDates ??
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

  double get actualTotal {
    if (unitActualPrices.isNotEmpty && unitActualPrices.any((p) => p != null)) {
      double sum = 0.0;
      for (int i = 0; i < purchasedQuantity; i++) {
        if (i < unitActualPrices.length && unitActualPrices[i] != null) {
          sum += unitActualPrices[i]!;
        } else if (actualPrice != null) {
          sum += actualPrice!;
        } else {
          sum += plannedPrice;
        }
      }
      return sum;
    }
    return purchasedQuantity * (actualPrice ?? plannedPrice);
  }

  double get effectiveTotal =>
      purchasedQuantity > 0 ? actualTotal : plannedTotal;

  PurchaseItem copyWith({
    String? id,
    String? groupId,
    String? subGroupId,
    String? name,
    int? quantity,
    double? plannedPrice,
    double? actualPrice,
    List<double?>? unitActualPrices,
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
      subGroupId: subGroupId ?? this.subGroupId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      plannedPrice: plannedPrice ?? this.plannedPrice,
      actualPrice: actualPrice ?? this.actualPrice,
      unitActualPrices: unitActualPrices ?? this.unitActualPrices,
      category: category ?? this.category,
      purchaseDates: updatedDates ?? this.purchaseDates,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'subGroupId': subGroupId,
      'name': name,
      'quantity': quantity,
      'plannedPrice': plannedPrice,
      'actualPrice': actualPrice,
      'unitActualPrices': unitActualPrices,
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

    List<double?> unitPrices = [];
    if (map['unitActualPrices'] != null) {
      final List<dynamic> list = map['unitActualPrices'];
      unitPrices = list.map((e) => e == null ? null : (e as num).toDouble()).toList();
    }

    return PurchaseItem(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? 'bike_touring',
      subGroupId: map['subGroupId'],
      name: map['name'] ?? '',
      quantity: qty,
      plannedPrice: (map['plannedPrice'] as num).toDouble(),
      actualPrice: map['actualPrice'] != null
          ? (map['actualPrice'] as num).toDouble()
          : null,
      unitActualPrices: unitPrices,
      category: map['category'] ?? 'Other',
      purchaseDates: dates,
      notes: map['notes'],
    );
  }
}
