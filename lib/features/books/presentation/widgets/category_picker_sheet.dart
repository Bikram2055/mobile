import 'package:flutter/material.dart';

import '../../data/models/expense_category.dart';

/// Full-height category picker. Shows the built-in master pool grouped into
/// sections, the user's own custom categories, and a button to create a new
/// one. Returns the chosen [ExpenseCategory] via [Navigator.pop].
class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({
    super.key,
    required this.selectedId,
    required this.customCategories,
  });

  final String? selectedId;
  final List<ExpenseCategory> customCategories;

  static Future<ExpenseCategory?> show(
    BuildContext context, {
    required String? selectedId,
    required List<ExpenseCategory> customCategories,
  }) {
    return showModalBottomSheet<ExpenseCategory>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryPickerSheet(
        selectedId: selectedId,
        customCategories: customCategories,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = ExpenseCategories.grouped;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Text(
                    'Choose a category',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final created = await CreateCategorySheet.show(context);
                      if (created != null && context.mounted) {
                        Navigator.of(context).pop(created);
                      }
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  if (customCategories.isNotEmpty) ...[
                    _SectionHeader('Your categories'),
                    _CategoryWrap(
                      categories: customCategories,
                      selectedId: selectedId,
                    ),
                    const SizedBox(height: 20),
                  ],
                  for (final group in groups) ...[
                    _SectionHeader(group.key),
                    _CategoryWrap(
                      categories: group.value,
                      selectedId: selectedId,
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _CategoryWrap extends StatelessWidget {
  const _CategoryWrap({
    required this.categories,
    required this.selectedId,
  });

  final List<ExpenseCategory> categories;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final category in categories)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: category.id == selectedId
                    ? category.color.withOpacity(0.16)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: category.id == selectedId ? category.color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(category.icon, size: 18, color: category.color),
                  const SizedBox(width: 8),
                  Text(
                    category.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: category.id == selectedId
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Sheet for creating a custom category: name, icon, and color. Returns the
/// built [ExpenseCategory] via [Navigator.pop].
class CreateCategorySheet extends StatefulWidget {
  const CreateCategorySheet({super.key});

  static Future<ExpenseCategory?> show(BuildContext context) {
    return showModalBottomSheet<ExpenseCategory>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateCategorySheet(),
    );
  }

  @override
  State<CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<CreateCategorySheet> {
  final TextEditingController _nameController = TextEditingController();
  String _iconId = CategoryIconCatalog.ids.first;
  Color _color = kCategoryColorPalette.first;
  bool _showNameError = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final id = 'custom-$slug-${DateTime.now().microsecondsSinceEpoch}';
    Navigator.of(context).pop(
      ExpenseCategory.custom(
        id: id,
        label: name,
        colorValue: _color.value,
        iconId: _iconId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewName = _nameController.text.trim().isEmpty
        ? 'New category'
        : _nameController.text.trim();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Create category',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              // Live preview.
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(CategoryIconCatalog.byId(_iconId), color: _color, size: 30),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      previewName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() => _showNameError = false),
                decoration: InputDecoration(
                  labelText: 'Category name',
                  hintText: 'e.g. Pet care',
                  errorText: _showNameError ? 'Enter a name' : null,
                ),
              ),
              const SizedBox(height: 20),
              Text('Icon', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final iconId in CategoryIconCatalog.ids)
                    GestureDetector(
                      onTap: () => setState(() => _iconId = iconId),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _iconId == iconId
                              ? _color.withOpacity(0.18)
                              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _iconId == iconId ? _color : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          CategoryIconCatalog.byId(iconId),
                          color: _iconId == iconId ? _color : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Color', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final color in kCategoryColorPalette)
                    GestureDetector(
                      onTap: () => setState(() => _color = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _color.value == color.value
                                ? theme.colorScheme.onSurface
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: _color.value == color.value
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
