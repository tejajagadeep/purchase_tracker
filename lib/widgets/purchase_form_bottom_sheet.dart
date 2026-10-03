import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late List<TextEditingController> _unitPriceControllers;

  late String _selectedCategory;
  late String _selectedGroupId;
  String? _selectedSubGroupId;
  late List<DateTime?> _unitDates;
  late List<DateTime?> _savedUnitDates;

  final _priceInputFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d{0,12}(\.\d{0,2})?'),
  );
  final _qtyInputFormatter = LengthLimitingTextInputFormatter(6);

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;

    _nameController = TextEditingController(text: item?.name ?? '');
    final initialQty = item?.quantity ?? 1;

    _quantityController =
        TextEditingController(text: initialQty.toString());
    _plannedPriceController = TextEditingController(
      text: item != null ? item.plannedPrice.toStringAsFixed(0) : '',
    );

    _actualPriceController = TextEditingController(
      text: item?.actualPrice != null
          ? (initialQty > 1 ? item!.actualTotal.toStringAsFixed(0) : item!.actualPrice!.toStringAsFixed(0))
          : '',
    );

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

    _savedUnitDates = List<DateTime?>.generate(initialQty, (index) {
      if (item != null && index < item.purchaseDates.length) {
        return item.purchaseDates[index];
      }
      return null;
    });

    _unitPriceControllers = List<TextEditingController>.generate(initialQty, (index) {
      if (item != null &&
          index < item.unitActualPrices.length &&
          item.unitActualPrices[index] != null) {
        return TextEditingController(text: item.unitActualPrices[index]!.toStringAsFixed(0));
      }
      return TextEditingController(text: '');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _plannedPriceController.dispose();
    _actualPriceController.dispose();
    _notesController.dispose();
    for (final controller in _unitPriceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onQuantityChanged(String value) {
    final newQty = int.tryParse(value) ?? 1;
    if (newQty > 0) {
      setState(() {
        if (newQty > _unitDates.length) {
          final diff = newQty - _unitDates.length;
          _unitDates.addAll(List.generate(diff, (_) => null));
          _savedUnitDates.addAll(List.generate(diff, (_) => null));
          _unitPriceControllers.addAll(List.generate(diff, (_) => TextEditingController(text: '')));
        }
        _updateActualPriceFromUnits();
      });
    }
  }

  void _updateActualPriceFromUnits() {
    final qty = int.tryParse(_quantityController.text) ?? 1;
    final plannedP = double.tryParse(_plannedPriceController.text.trim()) ?? 0.0;

    if (qty > 1) {
      double sum = 0.0;
      int boughtCount = 0;
      for (int i = 0; i < _unitDates.length; i++) {
        if (_unitDates[i] != null) {
          boughtCount++;
          final pText = i < _unitPriceControllers.length ? _unitPriceControllers[i].text.trim() : '';
          final p = double.tryParse(pText);
          if (p != null) {
            sum += p;
          } else {
            sum += plannedP;
          }
        }
      }
      if (boughtCount > 0) {
        _actualPriceController.text = sum.toStringAsFixed(0);
      } else {
        _actualPriceController.text = '';
      }
    }
    setState(() {});
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
    final mainActualText = _actualPriceController.text.trim();
    final mainActual = double.tryParse(mainActualText);

    if (qty == 1) {
      if (_unitDates.isNotEmpty && _unitDates[0] != null) {
        return mainActual ?? plannedPrice;
      }
      return plannedPrice;
    }

    double actualSum = 0.0;
    int boughtCount = 0;

    for (int i = 0; i < qty; i++) {
      if (i < _unitDates.length && _unitDates[i] != null) {
        boughtCount++;
        final pText = i < _unitPriceControllers.length ? _unitPriceControllers[i].text.trim() : '';
        final p = double.tryParse(pText);
        if (p != null) {
          actualSum += p;
        } else if (mainActual != null) {
          actualSum += mainActual;
        } else {
          actualSum += plannedPrice;
        }
      }
    }

    return boughtCount > 0 ? actualSum : 0.0;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final qty = int.parse(_quantityController.text);
      final plannedPrice = double.parse(_plannedPriceController.text);
      final actualPriceText = _actualPriceController.text.trim();
      final actualPriceInput =
          actualPriceText.isNotEmpty ? double.tryParse(actualPriceText) : null;

      final validDates = _unitDates.take(qty).whereType<DateTime>().toList();
      final List<double?> unitPrices = [];
      double sumUnitPrices = 0.0;
      int boughtCount = 0;

      for (int i = 0; i < qty; i++) {
        if (i < _unitDates.length && _unitDates[i] != null) {
          boughtCount++;
          final pText = i < _unitPriceControllers.length ? _unitPriceControllers[i].text.trim() : '';
          final p = double.tryParse(pText);
          if (p != null) {
            unitPrices.add(p);
            sumUnitPrices += p;
          } else {
            unitPrices.add(null);
            sumUnitPrices += plannedPrice;
          }
        } else {
          unitPrices.add(null);
        }
      }

      final double? finalActualPrice = qty > 1
          ? (boughtCount > 0 ? sumUnitPrices / boughtCount : null)
          : actualPriceInput;

      final bool isCompletedVal = validDates.length >= qty || (_unitDates.isNotEmpty && _unitDates[0] != null);

      final newItem = PurchaseItem(
        id: widget.existingItem?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        groupId: _selectedGroupId,
        subGroupId: _selectedSubGroupId,
        name: _nameController.text.trim(),
        quantity: qty,
        plannedPrice: plannedPrice,
        actualPrice: finalActualPrice,
        unitActualPrices: unitPrices,
        category: _selectedCategory,
        purchaseDates: validDates,
        isCompleted: isCompletedVal,
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
    final plannedP = double.tryParse(_plannedPriceController.text.trim()) ?? 0.0;

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
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete "${widget.existingItem?.name}"?'),
                            content: const Text(
                              'Are you sure you want to delete this purchase item? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          widget.onDelete!();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Group Dropdown (Move item to another group)
              if (widget.groups != null && widget.groups!.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  isExpanded: true,
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
                        _selectedSubGroupId = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Sub-Group / Month Dropdown (Move item to sub-group)
              if (availableSubs.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  isExpanded: true,
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
                      child: Text('Main Group (No Sub-Group)', overflow: TextOverflow.ellipsis),
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

              // Line 1: Item Name
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

              // Line 2: Planned Quantity & Planned Price Row
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _qtyInputFormatter,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Planned Qty *',
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
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _plannedPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [_priceInputFormatter],
                      decoration: const InputDecoration(
                        labelText: 'Planned Price (₹) *',
                        hintText: '8000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      onChanged: (_) {
                        _updateActualPriceFromUnits();
                      },
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

              // Line 3: Actual Price (Full Width, max 12 digits)
              TextFormField(
                controller: _actualPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_priceInputFormatter],
                decoration: const InputDecoration(
                  labelText: 'Actual Price (₹) (Optional)',
                  hintText: 'Leave empty if same as planned',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 12),

              // Line 4: Category Dropdown (On Line 4)
              DropdownButtonFormField<String>(
                isExpanded: true,
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

              const SizedBox(height: 12),

              // Line 5: Notes
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

              // Purchase Dates & Per-Unit Actual Price List
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
                      _unitDates[0] = val ? (_savedUnitDates[0] ?? DateTime.now()) : null;
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
                          _savedUnitDates[0] = picked;
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
                // Multiple Quantity Unit Purchase Dates & Prices List
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
                              'Unit Purchases ($purchasedUnitCount of ${_unitDates.length} Bought)',
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
                                    (i) => allBought ? null : (_savedUnitDates[i] ?? DateTime.now()),
                                  );
                                  _updateActualPriceFromUnits();
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
                                      _unitDates[index] = val == true
                                          ? (_savedUnitDates[index] ?? DateTime.now())
                                          : null;
                                      _updateActualPriceFromUnits();
                                    });
                                  },
                                ),
                                Text(
                                  'Unit ${index + 1}:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 3,
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
                                                if (index < _savedUnitDates.length) {
                                                  _savedUnitDates[index] = picked;
                                                }
                                              });
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.calendar_month,
                                            size: 14,
                                          ),
                                          label: Text(
                                            formatDate(_unitDates[index]!),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                        )
                                      : const Text(
                                          'Pending',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic,
                                            fontSize: 12,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _unitPriceControllers[index],
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [_priceInputFormatter],
                                    enabled: isBought,
                                    decoration: InputDecoration(
                                      labelText: 'Paid (₹)',
                                      hintText: plannedP > 0 ? plannedP.toStringAsFixed(0) : '50',
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      isDense: true,
                                    ),
                                    onChanged: (_) {
                                      _updateActualPriceFromUnits();
                                    },
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
