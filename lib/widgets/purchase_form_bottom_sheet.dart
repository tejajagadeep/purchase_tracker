import 'package:flutter/material.dart';
import '../constants/categories.dart';
import '../models/purchase_group.dart';
import '../models/purchase_item.dart';
import '../models/sub_group.dart';
import '../utils/formatters.dart';

class PurchaseFormBottomSheet extends StatefulWidget {
  final PurchaseItem? existingItem;
  final List<String> categories;
  final List<PurchaseGroup>? groups;
  final List<SubGroup>? allSubGroups;
  final String groupId;
  final String? subGroupId;
  final ValueChanged<PurchaseItem> onSave;
  final VoidCallback? onDelete;

  const PurchaseFormBottomSheet({
    super.key,
    this.existingItem,
    required this.categories,
    this.groups,
    this.allSubGroups,
    this.groupId = 'bike_touring',
    this.subGroupId,
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
  late String _selectedGroupId;
  String? _selectedSubGroupId;
  late List<DateTime?> _unitDates;
  bool _isTotalActualPriceMode = true;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;

    _nameController = TextEditingController(text: item?.name ?? '');
    final initialQty = item?.quantity ?? 1;
    _isTotalActualPriceMode = initialQty > 1;

    _quantityController =
        TextEditingController(text: initialQty.toString());
    _plannedPriceController = TextEditingController(
      text: item != null ? item.plannedPrice.toStringAsFixed(0) : '',
    );

    if (item?.actualPrice != null) {
      if (initialQty > 1) {
        _actualPriceController = TextEditingController(
          text: (initialQty * item!.actualPrice!).toStringAsFixed(0),
        );
      } else {
        _actualPriceController = TextEditingController(
          text: item!.actualPrice!.toStringAsFixed(0),
        );
      }
    } else {
      _actualPriceController = TextEditingController(text: '');
    }

    _notesController = TextEditingController(text: item?.notes ?? '');

    if (item != null && widget.categories.contains(item.category)) {
      _selectedCategory = item.category;
    } else {
      _selectedCategory =
          widget.categories.isNotEmpty ? widget.categories.first : CategoryConstants.defaultCategories.first;
    }

    _selectedGroupId = item?.groupId ?? widget.groupId;
    _selectedSubGroupId = item?.subGroupId ?? widget.subGroupId;

    _unitDates = List<DateTime?>.generate(initialQty, (index) {
      if (item != null && index < item.purchaseDates.length) {
        return item.purchaseDates[index];
      }
      return null;
    });
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

  void _onQuantityChanged(String value) {
    final newQty = int.tryParse(value) ?? 1;
    if (newQty > 0) {
      setState(() {
        if (newQty > _unitDates.length) {
          _unitDates.addAll(List.generate(newQty - _unitDates.length, (_) => null));
        } else if (newQty < _unitDates.length) {
          _unitDates = _unitDates.sublist(0, newQty);
        }
      });
    }
  }

  List<SubGroup> get _availableSubGroups {
    if (widget.allSubGroups == null) return [];
    return widget.allSubGroups!
        .where((sg) => sg.groupId == _selectedGroupId)
        .toList();
  }

  double get _calculatedTotal {
    final qty = int.tryParse(_quantityController.text) ?? 1;
    final plannedPrice = double.tryParse(_plannedPriceController.text) ?? 0.0;
    final actualText = _actualPriceController.text.trim();
    if (actualText.isNotEmpty) {
      final enteredActual = double.tryParse(actualText);
      if (enteredActual != null) {
        if (qty > 1 && _isTotalActualPriceMode) {
          return enteredActual;
        } else {
          return qty * enteredActual;
        }
      }
    }
    return qty * plannedPrice;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final qty = int.parse(_quantityController.text);
      final plannedPrice = double.parse(_plannedPriceController.text);
      final actualPriceText = _actualPriceController.text.trim();

      double? unitActualPrice;
      if (actualPriceText.isNotEmpty) {
        final enteredActual = double.tryParse(actualPriceText);
        if (enteredActual != null) {
          if (qty > 1 && _isTotalActualPriceMode) {
            unitActualPrice = enteredActual / qty;
          } else {
            unitActualPrice = enteredActual;
          }
        }
      }

      final validDates = _unitDates.whereType<DateTime>().toList();

      final newItem = PurchaseItem(
        id: widget.existingItem?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        groupId: _selectedGroupId,
        subGroupId: _selectedSubGroupId,
        name: _nameController.text.trim(),
        quantity: qty,
        plannedPrice: plannedPrice,
        actualPrice: unitActualPrice,
        category: _selectedCategory,
        purchaseDates: validDates,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      widget.onSave(newItem);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingItem != null;
    final purchasedUnitCount = _unitDates.where((d) => d != null).length;
    final availableSubs = _availableSubGroups;
    final currentQty = int.tryParse(_quantityController.text) ?? 1;

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

              // Group Dropdown (Move item to another group)
              if (widget.groups != null && widget.groups!.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Group / Trip',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                  items: widget.groups!.map((g) {
                    return DropdownMenuItem(
                      value: g.id,
                      child: Text(g.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedGroupId = val;
                        _selectedSubGroupId = null; // Reset subgroup when group changes
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Sub-Group / Month Dropdown (Move item to sub-group)
              if (availableSubs.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  initialValue: availableSubs.any((s) => s.id == _selectedSubGroupId)
                      ? _selectedSubGroupId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Sub-Group / Month (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder_special_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Main Group (No Sub-Group)'),
                    ),
                    ...availableSubs.map((sg) {
                      return DropdownMenuItem<String?>(
                        value: sg.id,
                        child: Text(sg.name, overflow: TextOverflow.ellipsis),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedSubGroupId = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],

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
                      onChanged: _onQuantityChanged,
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

              // Actual Paid Price Section
              if (currentQty > 1) ...[
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Total Paid'),
                      icon: Icon(Icons.receipt_outlined, size: 16),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Price Per Item'),
                      icon: Icon(Icons.sell_outlined, size: 16),
                    ),
                  ],
                  selected: {_isTotalActualPriceMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _isTotalActualPriceMode = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 8),
              ],

              TextFormField(
                controller: _actualPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: currentQty > 1
                      ? (_isTotalActualPriceMode
                          ? 'Total Actual Paid for all $currentQty items (₹)'
                          : 'Actual Price Paid per item (₹)')
                      : 'Actual Price Paid (₹) (Optional)',
                  hintText: currentQty > 1
                      ? (_isTotalActualPriceMode
                          ? 'e.g. 447 for all $currentQty items'
                          : 'e.g. 50 per item')
                      : 'Leave empty if same as planned',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.sell_outlined),
                  helperText: (currentQty > 1 &&
                          _actualPriceController.text.trim().isNotEmpty)
                      ? () {
                          final val = double.tryParse(_actualPriceController.text.trim());
                          if (val == null) return null;
                          if (_isTotalActualPriceMode) {
                            return '₹${val.toStringAsFixed(0)} total ÷ $currentQty items = ${formatCurrency(val / currentQty)} per item';
                          } else {
                            return '₹${val.toStringAsFixed(0)} × $currentQty items = ${formatCurrency(val * currentQty)} total';
                          }
                        }()
                      : null,
                ),
                onChanged: (_) => setState(() {}),
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

              const SizedBox(height: 16),

              // Purchase Dates per Unit Section
              if (_unitDates.length == 1) ...[
                // Single Quantity Toggle & Date Picker
                SwitchListTile(
                  title: const Text('Mark as Purchased'),
                  subtitle: Text(
                    _unitDates[0] != null
                        ? 'Bought on ${formatDate(_unitDates[0]!)}'
                        : 'Item is pending',
                  ),
                  value: _unitDates[0] != null,
                  onChanged: (val) {
                    setState(() {
                      _unitDates[0] = val ? DateTime.now() : null;
                    });
                  },
                ),
                if (_unitDates[0] != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _unitDates[0] ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _unitDates[0] = picked;
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
                        formatDate(_unitDates[0]!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ] else ...[
                // Multiple Quantity Unit Purchase Dates List
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Unit Purchase Dates ($purchasedUnitCount of ${_unitDates.length} Bought)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  final allBought = purchasedUnitCount == _unitDates.length;
                                  _unitDates = List.generate(
                                    _unitDates.length,
                                    (_) => allBought ? null : DateTime.now(),
                                  );
                                });
                              },
                              child: Text(
                                purchasedUnitCount == _unitDates.length
                                    ? 'Clear All'
                                    : 'Mark All Bought',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_unitDates.length, (index) {
                          final isBought = _unitDates[index] != null;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isBought,
                                  onChanged: (val) {
                                    setState(() {
                                      _unitDates[index] =
                                          val == true ? DateTime.now() : null;
                                    });
                                  },
                                ),
                                Text(
                                  'Unit ${index + 1}:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: isBought
                                      ? OutlinedButton.icon(
                                          onPressed: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate:
                                                  _unitDates[index] ?? DateTime.now(),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );
                                            if (picked != null) {
                                              setState(() {
                                                _unitDates[index] = picked;
                                              });
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.calendar_month,
                                            size: 16,
                                          ),
                                          label: Text(
                                            formatDate(_unitDates[index]!),
                                          ),
                                        )
                                      : const Text(
                                          'Pending',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
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
