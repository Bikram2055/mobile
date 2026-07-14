import 'package:flutter/material.dart';

import 'expense.dart';

/// A spending/earning category shown when logging an entry and used to group
/// totals in the analytics dashboard.
///
/// Categories come from two places:
///  * the built-in [ExpenseCategories.all] master pool, grouped into sections
///    like "Housing & Utilities" or "Food & Dining"; and
///  * user-created custom categories, which are denormalized onto each
///    [Expense] so they render everywhere (including shared books) without a
///    separate lookup.
@immutable
class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.group = 'Other',
    this.isCustom = false,
    this.iconId,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String group;
  final bool isCustom;

  /// Icon catalog id — set only for custom categories so it can be denormalized
  /// back onto an [Expense].
  final String? iconId;

  /// Builds a category from custom values chosen by the user.
  factory ExpenseCategory.custom({
    required String id,
    required String label,
    required int colorValue,
    required String iconId,
  }) {
    return ExpenseCategory(
      id: id,
      label: label,
      icon: CategoryIconCatalog.byId(iconId),
      color: Color(colorValue),
      group: 'Your categories',
      isCustom: true,
      iconId: iconId,
    );
  }
}

/// Central catalog of the built-in categories plus resolution helpers.
class ExpenseCategories {
  ExpenseCategories._();

  static const String fallbackId = 'other';

  /// Master pool, ordered by group. The group labels double as the section
  /// headers in the category picker.
  static const List<ExpenseCategory> all = <ExpenseCategory>[
    // Housing & Utilities
    ExpenseCategory(
      id: 'housing',
      label: 'Housing & Rent',
      icon: Icons.home_rounded,
      color: Color(0xFF7E57C2),
      group: 'Housing & Utilities',
    ),
    ExpenseCategory(
      id: 'utilities',
      label: 'Utilities',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFB300),
      group: 'Housing & Utilities',
    ),
    ExpenseCategory(
      id: 'bills',
      label: 'Bills',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF5C6BC0),
      group: 'Housing & Utilities',
    ),
    // Food & Dining
    ExpenseCategory(
      id: 'food',
      label: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF7043),
      group: 'Food & Dining',
    ),
    ExpenseCategory(
      id: 'groceries',
      label: 'Groceries',
      icon: Icons.local_grocery_store_rounded,
      color: Color(0xFF66BB6A),
      group: 'Food & Dining',
    ),
    ExpenseCategory(
      id: 'coffee',
      label: 'Coffee & Cafe',
      icon: Icons.local_cafe_rounded,
      color: Color(0xFF8D6E63),
      group: 'Food & Dining',
    ),
    // Transportation
    ExpenseCategory(
      id: 'transport',
      label: 'Transport',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF42A5F5),
      group: 'Transportation',
    ),
    ExpenseCategory(
      id: 'fuel',
      label: 'Fuel / Gas',
      icon: Icons.local_gas_station_rounded,
      color: Color(0xFFEF6C00),
      group: 'Transportation',
    ),
    ExpenseCategory(
      id: 'transit',
      label: 'Public Transit',
      icon: Icons.directions_bus_rounded,
      color: Color(0xFF26A69A),
      group: 'Transportation',
    ),
    // Healthcare
    ExpenseCategory(
      id: 'health',
      label: 'Healthcare',
      icon: Icons.favorite_rounded,
      color: Color(0xFFEF5350),
      group: 'Healthcare',
    ),
    ExpenseCategory(
      id: 'fitness',
      label: 'Fitness & Gym',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFAB47BC),
      group: 'Healthcare',
    ),
    // Debt & Savings
    ExpenseCategory(
      id: 'savings',
      label: 'Savings',
      icon: Icons.savings_rounded,
      color: Color(0xFF43A047),
      group: 'Debt & Savings',
    ),
    ExpenseCategory(
      id: 'debt',
      label: 'Debt / Loan',
      icon: Icons.credit_card_rounded,
      color: Color(0xFFE53935),
      group: 'Debt & Savings',
    ),
    // Lifestyle
    ExpenseCategory(
      id: 'shopping',
      label: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFEC407A),
      group: 'Lifestyle',
    ),
    ExpenseCategory(
      id: 'entertainment',
      label: 'Entertainment',
      icon: Icons.movie_rounded,
      color: Color(0xFF7E57C2),
      group: 'Lifestyle',
    ),
    ExpenseCategory(
      id: 'travel',
      label: 'Travel',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF29B6F6),
      group: 'Lifestyle',
    ),
    ExpenseCategory(
      id: 'education',
      label: 'Education',
      icon: Icons.school_rounded,
      color: Color(0xFFFFA726),
      group: 'Lifestyle',
    ),
    ExpenseCategory(
      id: 'gifts',
      label: 'Gifts',
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFFF8A65),
      group: 'Lifestyle',
    ),
    // Income
    ExpenseCategory(
      id: 'salary',
      label: 'Salary',
      icon: Icons.payments_rounded,
      color: Color(0xFF26C6DA),
      group: 'Income',
    ),
    // Other
    ExpenseCategory(
      id: 'other',
      label: 'Other',
      icon: Icons.category_rounded,
      color: Color(0xFF78909C),
      group: 'Other',
    ),
  ];

  static final Map<String, ExpenseCategory> _byId = {
    for (final category in all) category.id: category,
  };

  /// Ordered list of `(groupName, categories)` for the picker sections.
  static List<MapEntry<String, List<ExpenseCategory>>> get grouped {
    final order = <String>[];
    final map = <String, List<ExpenseCategory>>{};
    for (final category in all) {
      if (!map.containsKey(category.group)) {
        order.add(category.group);
        map[category.group] = <ExpenseCategory>[];
      }
      map[category.group]!.add(category);
    }
    return [for (final group in order) MapEntry(group, map[group]!)];
  }

  /// Returns the built-in category for [id], or null if it is not a built-in.
  static ExpenseCategory? builtinById(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    return _byId[id.toLowerCase()];
  }

  /// Resolves any [id] to a category, falling back to "Other".
  static ExpenseCategory byId(String? id) {
    return builtinById(id) ?? _byId[fallbackId]!;
  }

  /// Resolves the category to display for [expense].
  ///
  /// Built-in ids resolve from the master pool. Custom entries fall back to the
  /// denormalized label/color/icon stored on the expense, so they render even
  /// when the owner's custom list isn't available (e.g. shared books).
  static ExpenseCategory forExpense(Expense expense) {
    final builtin = builtinById(expense.categoryId);
    if (builtin != null) {
      return builtin;
    }
    final label = expense.categoryLabel;
    if (label != null && label.isNotEmpty) {
      return ExpenseCategory.custom(
        id: expense.categoryId,
        label: label,
        colorValue: expense.categoryColorValue ?? 0xFF78909C,
        iconId: expense.categoryIconId ?? 'category',
      );
    }
    return _byId[fallbackId]!;
  }
}

/// Curated icons offered when creating a custom category. Stored on the expense
/// as a string id so the model stays free of Flutter types and icon
/// tree-shaking keeps working (all IconData here are const).
class CategoryIconCatalog {
  CategoryIconCatalog._();

  static const Map<String, IconData> _icons = <String, IconData>{
    'category': Icons.category_rounded,
    'home': Icons.home_rounded,
    'bolt': Icons.bolt_rounded,
    'receipt': Icons.receipt_long_rounded,
    'restaurant': Icons.restaurant_rounded,
    'grocery': Icons.local_grocery_store_rounded,
    'coffee': Icons.local_cafe_rounded,
    'car': Icons.directions_car_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'bus': Icons.directions_bus_rounded,
    'flight': Icons.flight_takeoff_rounded,
    'health': Icons.favorite_rounded,
    'fitness': Icons.fitness_center_rounded,
    'medication': Icons.medication_rounded,
    'savings': Icons.savings_rounded,
    'card': Icons.credit_card_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'movie': Icons.movie_rounded,
    'school': Icons.school_rounded,
    'gift': Icons.card_giftcard_rounded,
    'pets': Icons.pets_rounded,
    'child': Icons.child_care_rounded,
    'work': Icons.work_rounded,
    'phone': Icons.smartphone_rounded,
    'wifi': Icons.wifi_rounded,
    'sports': Icons.sports_esports_rounded,
    'beauty': Icons.spa_rounded,
    'money': Icons.payments_rounded,
  };

  static List<String> get ids => _icons.keys.toList(growable: false);

  static IconData byId(String? id) =>
      _icons[id] ?? Icons.category_rounded;
}

/// Palette offered when creating a custom category.
const List<Color> kCategoryColorPalette = <Color>[
  Color(0xFFEF5350),
  Color(0xFFEC407A),
  Color(0xFFAB47BC),
  Color(0xFF7E57C2),
  Color(0xFF5C6BC0),
  Color(0xFF42A5F5),
  Color(0xFF29B6F6),
  Color(0xFF26C6DA),
  Color(0xFF26A69A),
  Color(0xFF66BB6A),
  Color(0xFF9CCC65),
  Color(0xFFFFB300),
  Color(0xFFFF7043),
  Color(0xFF8D6E63),
  Color(0xFF78909C),
];
