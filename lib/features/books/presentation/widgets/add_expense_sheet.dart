import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/expense.dart';
import '../../data/models/expense_category.dart';
import '../controllers/book_controller.dart';
import 'category_picker_sheet.dart';
import 'receipt_preview.dart';

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({
    super.key,
    required this.bookId,
    this.expense,
    this.isIncome = false,
  });

  final String bookId;
  final Expense? expense;
  final bool isIncome;

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late DateTime _selectedDate;
  String? _receiptData;
  late ExpenseType _type;
  late ExpenseCategory _selectedCategory;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _type = expense?.type ?? (widget.isIncome ? ExpenseType.income : ExpenseType.expense);
    if (expense != null) {
      _descriptionController.text = expense.description;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _selectedDate = expense.date;
      _receiptData = expense.receiptData;
      _selectedCategory = ExpenseCategories.forExpense(expense);
    } else {
      _selectedDate = DateTime.now();
      _selectedCategory = ExpenseCategories.byId(_type == ExpenseType.income ? 'salary' : 'food');
    }
  }

  /// Distinct custom categories already used across the user's books, so they
  /// can be reused from the picker.
  List<ExpenseCategory> _customCategories(BookController controller) {
    final seen = <String>{};
    final result = <ExpenseCategory>[];
    for (final book in controller.books) {
      for (final expense in book.expenses) {
        if (ExpenseCategories.builtinById(expense.categoryId) != null) {
          continue;
        }
        if (seen.add(expense.categoryId)) {
          result.add(ExpenseCategories.forExpense(expense));
        }
      }
    }
    return result;
  }

  Future<void> _pickCategory(BookController controller) async {
    final picked = await CategoryPickerSheet.show(
      context,
      selectedId: _selectedCategory.id,
      customCategories: _customCategories(controller),
    );
    if (picked != null) {
      setState(() => _selectedCategory = picked);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _receiptData = base64Encode(bytes);
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final controller = context.read<BookController>();
    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final existingExpense = widget.expense;
    final expense = Expense(
      id: existingExpense?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      description: _descriptionController.text.trim(),
      amount: amount,
      date: _selectedDate,
      receiptData: _receiptData,
      type: _type,
      categoryId: _selectedCategory.id,
      // Only custom categories carry denormalized display info; built-ins
      // resolve from the master pool by id.
      categoryLabel: _selectedCategory.isCustom ? _selectedCategory.label : null,
      categoryColorValue: _selectedCategory.isCustom ? _selectedCategory.color.value : null,
      categoryIconId: _selectedCategory.isCustom ? _selectedCategory.iconId : null,
    );

    bool success;
    if (_isEditing) {
      success = await controller.updateExpense(bookId: widget.bookId, expense: expense);
    } else {
      await controller.addExpense(bookId: widget.bookId, expense: expense);
      success = controller.errorMessage == null;
    }

    if (!mounted) {
      return;
    }

    final isIncome = _type == ExpenseType.income;
    if (!success) {
      final fallback = _isEditing
          ? 'Failed to update the ${isIncome ? 'income' : 'expense'}.'
          : 'Failed to add the ${isIncome ? 'income' : 'expense'}.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage ?? fallback)),
      );
      return;
    }

    Navigator.of(context).pop();
    final formattedAmount = NumberFormat.currency(
      locale: 'en_IN',
      name: 'NPR',
      symbol: 'Rs ',
    ).format(expense.amount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? '${isIncome ? 'Income' : 'Expense'} updated ($formattedAmount).'
            : '$formattedAmount ${isIncome ? 'added as income' : 'logged successfully'}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Consumer<BookController>(
          builder: (context, controller, _) {
            final isSaving = controller.isSaving;
            final isIncome = _type == ExpenseType.income;
            final currency = NumberFormat.currency(
              locale: 'en_IN',
              name: 'NPR',
              symbol: 'Rs ',
            );

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isEditing
                          ? 'Edit ${_type == ExpenseType.income ? 'income' : 'expense'}'
                          : 'Add ${_type == ExpenseType.income ? 'income' : 'expense'}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'What is this for?',
                        hintText: 'e.g. Salary or Groceries',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Describe the entry';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: currency.currencySymbol,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter the amount';
                        }
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed <= 0) {
                          return 'Amount must be greater than zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Category',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CategoryField(
                      category: _selectedCategory,
                      onTap: isSaving ? null : () => _pickCategory(controller),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
                                const SizedBox(width: 12),
                                Text(DateFormat('MMM d, y').format(_selectedDate)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: isSaving ? null : _selectDate,
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.image_outlined, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              Text(
                                'Receipt (optional)',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: isSaving ? null : _chooseImage,
                                child: Text(
                                  _receiptData == null || _receiptData!.isEmpty ? 'Add' : 'Change',
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_receiptData != null && _receiptData!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: double.infinity,
                                height: 180,
                                child: ReceiptPreview(
                                  base64Data: _receiptData,
                                ),
                              ),
                            )
                          else
                            Text(
                              'Attach a photo of a receipt to keep everything organised.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () {
                                    Navigator.of(context).maybePop();
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  )
                                : Text(
                                    _isEditing
                                        ? 'Update ${isIncome ? 'income' : 'expense'}'
                                        : 'Save ${isIncome ? 'income' : 'expense'}',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A tappable field showing the currently selected category; opens the full
/// [CategoryPickerSheet] when tapped.
class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.category,
    required this.onTap,
  });

  final ExpenseCategory category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: category.color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: category.color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    category.isCustom ? 'Custom category' : category.group,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
