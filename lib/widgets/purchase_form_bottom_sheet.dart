import 'package:flutter/material.dart';
import '../constants/categories.dart';
import '../models/purchase_item.dart';
import '../utils/formatters.dart';

class PurchaseFormBottomSheet extends StatefulWidget {
  final PurchaseItem? existingItem;
  final List<String> categories;
  final String groupId;
  final ValueChanged<PurchaseItem> onSave;
  final VoidCallback? onDelete;

  const PurchaseFormBottomSheet({
    super.key,
    this.existingItem,
    required this.categories,
    this.groupId = 'bike_touring',
    required this.onSave,
    this.onDelete,
  });

  @override
  State<PurchaseFormBottomSheet> createState() =>
      _PurchaseFormBottomSheetState();
}

class _PurchaseFormBottomSheetState
    extends State<PurchaseFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _plannedPriceController;
  late TextEditingController _actualPriceController;
  late TextEditingController _notesController;

  late String _selectedCategory;
  late bool _isPurchased;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;

    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController =
        TextEditingController(text: (item?.quantity ?? 1).toString());
    _plannedPriceController = TextEditingController(
      text: item != null ? item.plannedPrice.toStringAsFixed(0) : '',
    );
    _actualPriceController = TextEditingController(
      text: item?.actualPrice != null
          ? item!.actualPrice!.toStringAsFixed(0)
          : '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');

    if (item != null && widget.categories.contains(item.category)) {
      _selectedCategory = item.category;
    } else {
      _selectedCategory =
          widget.categories.isNotEmpty ? widget.categories.first : CategoryConstants.defaultCategories.first;
    }

    _isPurchased = item?.isPurchased ?? false;
    _selectedDate =
        item?.datePurchased ?? (_isPurchased ? DateTime.now() : null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _plannedPriceController.dispose();
    _actualPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _calculatedTotal {
    final qty = int.tryParse(_quantityController.text) ?? 1;
    final price = double.tryParse(_plannedPriceController.text) ?? 0.0;
    return qty * price;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final qty = int.parse(_quantityController.text);
      final plannedPrice = double.parse(_plannedPriceController.text);
      final actualPriceText = _actualPriceController.text.trim();
      final actualPrice =
          actualPriceText.isNotEmpty ? double.tryParse(actualPriceText) : null;

      final newItem = PurchaseItem(
        id: widget.existingItem?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        groupId: widget.existingItem?.groupId ?? widget.groupId,
        name: _nameController.text.trim(),
        quantity: qty,
        plannedPrice: plannedPrice,
        actualPrice: actualPrice,
        category: _selectedCategory,
        isPurchased: _isPurchased,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        datePurchased:
            _isPurchased ? (_selectedDate ?? DateTime.now()) : null,
      );

      widget.onSave(newItem);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingItem != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottomsheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Purchase' : 'Add New Purchase',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isEditing && widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        widget.onDelete!();
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Item Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g. Riding Jacket',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Quantity & Planned Price Row
              Row(
                children: [
                  // Quantity
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final n = int.tryParse(value);
                        if (n == null || n < 1) {
                          return 'Min 1';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Planned Price per item
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _plannedPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Planned Price (₹) *',
                        hintText: '8000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter price';
                        }
                        final p = double.tryParse(value);
                        if (p == null || p < 0) {
                          return 'Invalid price';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Category & Actual Price Row
              Row(
                children: [
                  // Category Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: widget.categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Actual Paid Price (Optional)
              TextFormField(
                controller: _actualPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Actual Price Paid per item (Optional)',
                  hintText: 'Leave empty if same as planned',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
              ),

              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Fitting Costs (Optional)',
                  hintText: 'e.g. ₹6,000 + ₹250 fitting',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),

              const SizedBox(height: 12),

              // Purchased Switch
              SwitchListTile(
                title: const Text('Mark as Purchased'),
                subtitle: Text(
                  _isPurchased
                      ? 'Item bought & added to actual spent'
                      : 'Item is still pending',
                ),
                value: _isPurchased,
                onChanged: (val) {
                  setState(() {
                    _isPurchased = val;
                    if (_isPurchased && _selectedDate == null) {
                      _selectedDate =
                          widget.existingItem?.datePurchased ?? DateTime.now();
                    }
                  });
                },
              ),

              // Clear Purchase Date Selector Field when Marked as Purchased
              if (_isPurchased) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Purchase Date *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      formatDate(_selectedDate ?? DateTime.now()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Total Calculation Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calculated Total:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      formatCurrency(_calculatedTotal),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.save),
                  label: Text(
                    isEditing ? 'Save Changes' : 'Add Purchase',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
