import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/category_model.dart';
import '../utils/app_state.dart';
import '../utils/app_language.dart';
import '../utils/icon_options.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _type = 'expense';

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context);
    final appState = Provider.of<AppState>(context);
    final categories = appState.categoriesFor(_type);

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('manage_categories'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'expense', label: Text(lang.t('expense'))),
                ButtonSegment(value: 'income', label: Text(lang.t('income'))),
              ],
              selected: {_type},
              onSelectionChanged: (val) => setState(() => _type = val.first),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cat.color,
                    child: Icon(cat.icon, color: Colors.white, size: 20),
                  ),
                  title: Text(cat.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _openEditor(context, existing: cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _confirmDelete(context, cat),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CategoryModel cat) {
    final appState = Provider.of<AppState>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('"${cat.name}" delete करायची?'),
        content: const Text(
            'ही category delete होईल. आधीच्या entries वर परिणाम होणार नाही, पण त्या entries आता या category सोबत दिसणार नाहीत.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('नको')),
          TextButton(
            onPressed: () {
              appState.deleteCategory(cat.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete करा'),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, {CategoryModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CategoryEditorSheet(type: _type, existing: existing),
    );
  }
}

class _CategoryEditorSheet extends StatefulWidget {
  final String type;
  final CategoryModel? existing;
  const _CategoryEditorSheet({required this.type, this.existing});

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  final _nameController = TextEditingController();
  late IconData _selectedIcon;
  late Color _selectedColor;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.existing!.name;
      _selectedIcon = widget.existing!.icon;
      _selectedColor = widget.existing!.color;
    } else {
      final icons = widget.type == 'income'
          ? IconOptions.incomeIcons
          : IconOptions.expenseIcons;
      _selectedIcon = icons.first;
      _selectedColor = IconOptions.colorPalette.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    final icons = widget.type == 'income'
        ? IconOptions.incomeIcons
        : IconOptions.expenseIcons;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? lang.t('edit_category') : lang.t('add_category'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 30,
                backgroundColor: _selectedColor,
                child: Icon(_selectedIcon, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: lang.t('category_name'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(lang.t('choose_color'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: IconOptions.colorPalette.map((color) {
                final selected = color.value == _selectedColor.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: color,
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(lang.t('choose_icon'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: icons.length,
                itemBuilder: (context, index) {
                  final icon = icons[index];
                  final selected = icon.codePoint == _selectedIcon.codePoint;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: CircleAvatar(
                      backgroundColor:
                          selected ? _selectedColor : Colors.grey.shade200,
                      child: Icon(icon,
                          color: selected ? Colors.white : Colors.black54,
                          size: 20),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              style:
                  FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(isEditing ? lang.t('update') : lang.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;
    final appState = Provider.of<AppState>(context, listen: false);

    if (isEditing) {
      final updated = widget.existing!.copyWith(
        name: _nameController.text.trim(),
        iconCodePoint: _selectedIcon.codePoint,
        colorValue: _selectedColor.value,
      );
      appState.updateCategory(updated);
    } else {
      final newCat = CategoryModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        type: widget.type,
        iconCodePoint: _selectedIcon.codePoint,
        colorValue: _selectedColor.value,
      );
      appState.addCategory(newCat);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
