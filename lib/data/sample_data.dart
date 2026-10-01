import '../models/purchase_group.dart';
import '../models/purchase_item.dart';

List<PurchaseGroup> getInitialTemplateGroups() {
  return [
    PurchaseGroup(
      id: 'template_monthly_expenses',
      name: 'Monthly Expenses Template',
      description: 'Master template items for monthly food, rent, groceries, and bills',
      iconName: 'receipt_long',
      isTemplate: true,
    ),
    PurchaseGroup(
      id: 'template_touring_accessories',
      name: 'Touring Accessories Template',
      description: 'Master template items for touring accessories and gear',
      iconName: 'two_wheeler',
      isTemplate: true,
    ),
  ];
}

List<PurchaseItem> getInitialTemplateItems() {
  return [
    // Monthly Expenses Template Items
    PurchaseItem(
      id: 'tmpl_1',
      groupId: 'template_monthly_expenses',
      name: 'Rice bowl',
      quantity: 1,
      plannedPrice: 120,
      category: 'Food & Dining',
    ),
    PurchaseItem(
      id: 'tmpl_2',
      groupId: 'template_monthly_expenses',
      name: 'Biryani',
      quantity: 1,
      plannedPrice: 250,
      category: 'Food & Dining',
    ),
    PurchaseItem(
      id: 'tmpl_3',
      groupId: 'template_monthly_expenses',
      name: 'Dosa',
      quantity: 1,
      plannedPrice: 80,
      category: 'Food & Dining',
    ),
    PurchaseItem(
      id: 'tmpl_4',
      groupId: 'template_monthly_expenses',
      name: 'Milk',
      quantity: 30,
      plannedPrice: 30,
      category: 'Groceries & Supplies',
      notes: 'Daily packet',
    ),
    PurchaseItem(
      id: 'tmpl_5',
      groupId: 'template_monthly_expenses',
      name: 'Coffee',
      quantity: 30,
      plannedPrice: 20,
      category: 'Food & Dining',
    ),
    PurchaseItem(
      id: 'tmpl_6',
      groupId: 'template_monthly_expenses',
      name: 'Fuel & Petrol',
      quantity: 4,
      plannedPrice: 500,
      category: 'Fuel & Petrol',
    ),
    PurchaseItem(
      id: 'tmpl_7',
      groupId: 'template_monthly_expenses',
      name: 'House Rent',
      quantity: 1,
      plannedPrice: 15000,
      category: 'Rent & Housing',
    ),
    PurchaseItem(
      id: 'tmpl_8',
      groupId: 'template_monthly_expenses',
      name: 'Electricity & Utilities',
      quantity: 1,
      plannedPrice: 1500,
      category: 'Bills & Utilities',
    ),
    PurchaseItem(
      id: 'tmpl_9',
      groupId: 'template_monthly_expenses',
      name: 'Wifi & Internet',
      quantity: 1,
      plannedPrice: 800,
      category: 'Bills & Utilities',
    ),

    // Touring Accessories Template Items
    PurchaseItem(
      id: 'tmpl_10',
      groupId: 'template_touring_accessories',
      name: 'Riding jacket',
      quantity: 1,
      plannedPrice: 8000,
      category: 'Riding Gear',
    ),
    PurchaseItem(
      id: 'tmpl_11',
      groupId: 'template_touring_accessories',
      name: 'Shoes ×2',
      quantity: 2,
      plannedPrice: 5000,
      category: 'Riding Gear',
    ),
    PurchaseItem(
      id: 'tmpl_12',
      groupId: 'template_touring_accessories',
      name: 'Knee protector ×2',
      quantity: 2,
      plannedPrice: 3000,
      category: 'Riding Gear',
    ),
    PurchaseItem(
      id: 'tmpl_13',
      groupId: 'template_touring_accessories',
      name: 'Gloves',
      quantity: 1,
      plannedPrice: 2000,
      category: 'Riding Gear',
    ),
    PurchaseItem(
      id: 'tmpl_14',
      groupId: 'template_touring_accessories',
      name: 'Tent',
      quantity: 1,
      plannedPrice: 2500,
      category: 'Camping',
    ),
    PurchaseItem(
      id: 'tmpl_15',
      groupId: 'template_touring_accessories',
      name: 'Helmet',
      quantity: 1,
      plannedPrice: 5300,
      category: 'Safety & Protection',
    ),
  ];
}

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
      category: 'Luggage & Bags',
    ),
    PurchaseItem(
      id: '8',
      name: 'Other luggage bags',
      quantity: 1,
      plannedPrice: 30000,
      category: 'Luggage & Bags',
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
      category: 'Bike Tools & Parts',
    ),
    PurchaseItem(
      id: '13',
      name: 'Bike repair kit',
      quantity: 1,
      plannedPrice: 5000,
      category: 'Bike Tools & Parts',
    ),
    PurchaseItem(
      id: '14',
      name: 'Helmet',
      quantity: 1,
      plannedPrice: 5300,
      category: 'Safety & Protection',
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
