import '../models/purchase_item.dart';

/// Sample data populated on first launch based on touring accessories list
List<PurchaseItem> getInitialSampleData() {
  return [
    PurchaseItem(
      id: '1',
      name: 'Riding jacket',
      quantity: 1,
      plannedPrice: 8000,
      category: 'Riding Gear',
    ),
    PurchaseItem(
      id: '2',
      name: 'Shoes ×2',
      quantity: 2,
      plannedPrice: 5000,
      category: 'Riding Gear',
    ),
    PurchaseItem(
      id: '3',
      name: 'Knee protector ×2',
      quantity: 2,
      plannedPrice: 3000,
      category: 'Riding Gear',
    ),
    PurchaseItem(
      id: '4',
      name: 'Gloves',
      quantity: 1,
      plannedPrice: 2000,
      category: 'Riding Gear',
    ),
    PurchaseItem(
      id: '5',
      name: 'Tent',
      quantity: 1,
      plannedPrice: 2500,
      category: 'Camping',
    ),
    PurchaseItem(
      id: '6',
      name: 'Inflated Bed',
      quantity: 1,
      plannedPrice: 3000,
      category: 'Camping',
    ),
    PurchaseItem(
      id: '7',
      name: 'Steel luggage',
      quantity: 1,
      plannedPrice: 23000,
      category: 'Luggage',
    ),
    PurchaseItem(
      id: '8',
      name: 'Other luggage bags',
      quantity: 1,
      plannedPrice: 30000,
      category: 'Luggage',
    ),
    PurchaseItem(
      id: '9',
      name: 'DJI camera',
      quantity: 1,
      plannedPrice: 58000,
      category: 'Camera / Electronics',
    ),
    PurchaseItem(
      id: '10',
      name: 'EJEAS V6Pro+ Intercom',
      quantity: 1,
      plannedPrice: 6250,
      notes: '₹6,000 + ₹250 fitting',
      category: 'Camera / Electronics',
    ),
    PurchaseItem(
      id: '11',
      name: 'Fog lights',
      quantity: 1,
      plannedPrice: 20000,
      category: 'Bike Accessories',
    ),
    PurchaseItem(
      id: '12',
      name: 'Tyre inflator',
      quantity: 1,
      plannedPrice: 3000,
      category: 'Bike Tools',
    ),
    PurchaseItem(
      id: '13',
      name: 'Bike repair kit',
      quantity: 1,
      plannedPrice: 5000,
      category: 'Bike Tools',
    ),
    PurchaseItem(
      id: '14',
      name: 'Helmet',
      quantity: 1,
      plannedPrice: 5300,
      category: 'Safety',
    ),
    PurchaseItem(
      id: '15',
      name: 'Nylon 700x6x2',
      quantity: 1,
      plannedPrice: 8000,
      category: 'Other',
    ),
  ];
}
