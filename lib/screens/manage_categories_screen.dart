import 'package:flutter/material.dart';
import '../constants/categories.dart';

class ManageCategoriesScreen extends StatefulWidget {
  final List<String> currentCategories;
  final Function(List<String> updatedCategories, String? oldCategoryName, String? newCategoryName)
      onCategoriesUpdated;

  const ManageCategoriesScreen({
    super.key,
    required this.currentCategories,
    required this.onCategoriesUpdated,
  });

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = List<String>.from(widget.currentCategories);
  }

  void _saveAndNotify({String? oldName, String? newName}) {
    CategoryManager.saveCategories(_categories);
    widget.onCategoriesUpdated(_categories, oldName, newName);
  }

  void _showIconPickerDialog(String category, IconData currentIcon) {
    final nav = Navigator.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Icon for "$category"'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: CategoryConstants.selectableIcons.length,
            itemBuilder: (context, index) {
              final icon = CategoryConstants.selectableIcons[index];
              final isSelected = icon == currentIcon;
              return InkWell(
                onTap: () async {
                  await CategoryManager.saveCategoryIcon(category, icon);
                  setState(() {});
                  _saveAndNotify();
                  nav.pop();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g. Fuel & Travel',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter category name';
              }
              final name = value.trim();
              if (_categories.any((c) => c.toLowerCase() == name.toLowerCase())) {
                return 'Category already exists';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newName = controller.text.trim();
                setState(() {
                  _categories.add(newName);
                });
                _saveAndNotify();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "$newName" added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(int index) {
    final oldName = _categories[index];
    final controller = TextEditingController(text: oldName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter category name';
              }
              final name = value.trim();
              if (name.toLowerCase() != oldName.toLowerCase() &&
                  _categories.any((c) => c.toLowerCase() == name.toLowerCase())) {
                return 'Category already exists';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newName = controller.text.trim();
                if (newName != oldName) {
                  setState(() {
                    _categories[index] = newName;
                  });
                  _saveAndNotify(oldName: oldName, newName: newName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Updated to "$newName"')),
                  );
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(int index) {
    final catName = _categories[index];

    if (_categories.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one category is required.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$catName"?'),
        content: const Text(
          'Any purchase items assigned to this category will be reassigned to "Other" (or the first available category). Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _categories.removeAt(index);
              });
              final fallbackCat = _categories.contains('Other')
                  ? 'Other'
                  : _categories.first;
              _saveAndNotify(oldName: catName, newName: fallbackCat);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "$catName"')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaultCategories() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Categories'),
        content: const Text(
          'Reset categories list back to default categories?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _categories = List<String>.from(CategoryConstants.defaultCategories);
              });
              _saveAndNotify();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Categories reset to default!')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset to Defaults',
            onPressed: _resetToDefaultCategories,
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final catIcon = CategoryConstants.getIcon(cat);
          return Card(
            child: ListTile(
              leading: InkWell(
                onTap: () => _showIconPickerDialog(cat, catIcon),
                borderRadius: BorderRadius.circular(20),
                child: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    catIcon,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
              title: Text(
                cat,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Tap icon to change',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit Name',
                    onPressed: () => _showEditCategoryDialog(index),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: 'Delete Category',
                    onPressed: () => _deleteCategory(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }
}
