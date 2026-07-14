import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../books/data/models/book.dart';
import '../../../books/data/models/expense.dart';
import '../../../books/presentation/controllers/book_controller.dart';
import '../../domain/category_analytics.dart';
import '../widgets/category_bar_chart.dart';
import '../widgets/category_card.dart';
import '../widgets/doughnut_chart.dart';
import '../widgets/radial_bar_chart.dart';

/// Interactive analytics dashboard. Pass a [bookId] to scope to a single book,
/// or leave it null to aggregate across every book the user owns.
///
/// This screen intentionally uses its own vibrant accent palette so the charts
/// stay legible with many categories at once.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, this.bookId});

  final String? bookId;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const _gradientStart = Color(0xFF5B5BEF);
  static const _gradientEnd = Color(0xFF2BC0C6);

  final CategoryAnalytics _analytics = const CategoryAnalytics();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    name: 'NPR',
    symbol: 'Rs ',
  );
  final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: 'Rs ',
  );

  ExpenseType _type = ExpenseType.expense;
  String? _selectedCategoryId;
  String? _scopeBookId; // null = all books (only used in aggregate mode)

  String _formatCompact(double value) => _compact.format(value);

  @override
  void initState() {
    super.initState();
    _scopeBookId = widget.bookId;
  }

  List<Book> _scopedBooks(BookController controller) {
    final all = controller.books;
    final id = _scopeBookId;
    if (id == null) {
      return all;
    }
    return all.where((b) => b.id == id).toList();
  }

  void _toggleSelection(String? id) {
    setState(() => _selectedCategoryId = id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Consumer<BookController>(
        builder: (context, controller, _) {
          final books = _scopedBooks(controller);
          final breakdown = _analytics.breakdown(books, type: _type);
          // Selection may point at a category that no longer exists after a
          // type/scope switch; clear it so charts don't stay dimmed.
          if (_selectedCategoryId != null &&
              !breakdown.slices.any((s) => s.category.id == _selectedCategoryId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _selectedCategoryId = null);
              }
            });
          }

          return CustomScrollView(
            slivers: [
              _buildHeader(theme, controller, breakdown),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: _TypeToggle(
                    type: _type,
                    accent: _gradientStart,
                    onChanged: (value) => setState(() {
                      _type = value;
                      _selectedCategoryId = null;
                    }),
                  ),
                ),
              ),
              if (breakdown.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyAnalytics(type: _type),
                )
              else ...[
                _buildSummaryStrip(breakdown),
                _buildCategoryCards(breakdown),
                _buildChartSection(
                  title: 'Spending split',
                  subtitle: 'Tap a slice to focus a category',
                  child: Center(
                    child: DoughnutChart(
                      slices: breakdown.slices,
                      total: breakdown.total,
                      centerLabel: _type == ExpenseType.income ? 'Total income' : 'Total spent',
                      formatValue: _formatCompact,
                      selectedId: _selectedCategoryId,
                      onSelected: _toggleSelection,
                    ),
                  ),
                  breakdown: breakdown,
                ),
                _buildChartSection(
                  title: 'Category rings',
                  subtitle: 'Each ring is scaled to the largest category',
                  child: Center(
                    child: RadialBarChart(
                      slices: breakdown.slices,
                      formatValue: _formatCompact,
                      selectedId: _selectedCategoryId,
                      onSelected: _toggleSelection,
                    ),
                  ),
                  breakdown: breakdown,
                ),
                _buildChartSection(
                  title: 'Category totals',
                  subtitle: 'Scroll sideways · tap a bar to focus',
                  child: CategoryBarChart(
                    slices: breakdown.slices,
                    formatValue: _formatCompact,
                    selectedId: _selectedCategoryId,
                    onSelected: _toggleSelection,
                  ),
                  breakdown: breakdown,
                  showLegend: false,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    BookController controller,
    CategoryBreakdown breakdown,
  ) {
    final scopeLabel = widget.bookId != null
        ? (controller.bookById(widget.bookId!)?.title ?? 'Book')
        : (_scopeBookId == null
            ? 'All books'
            : controller.bookById(_scopeBookId!)?.title ?? 'Book');

    return SliverAppBar(
      pinned: true,
      expandedHeight: 210,
      backgroundColor: _gradientStart,
      foregroundColor: Colors.white,
      title: const Text('Analytics'),
      actions: [
        if (widget.bookId == null && controller.books.length > 1)
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter by book',
            initialValue: _scopeBookId,
            onSelected: (value) => setState(() {
              _scopeBookId = value;
              _selectedCategoryId = null;
            }),
            itemBuilder: (context) => [
              const PopupMenuItem<String?>(
                value: null,
                child: Text('All books'),
              ),
              const PopupMenuDivider(),
              ...controller.books.map(
                (b) => PopupMenuItem<String?>(
                  value: b.id,
                  child: Text(b.title),
                ),
              ),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_gradientStart, _gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insights_rounded, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          scopeLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currency.format(breakdown.total),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _type == ExpenseType.income
                        ? 'Total income across ${breakdown.categoryCount} categories'
                        : 'Total spent across ${breakdown.categoryCount} categories',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStrip(CategoryBreakdown breakdown) {
    final top = breakdown.top;
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 96,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          children: [
            _MetricPill(
              icon: Icons.receipt_long_rounded,
              label: 'Entries',
              value: '${breakdown.entryCount}',
              color: _gradientStart,
            ),
            _MetricPill(
              icon: Icons.category_rounded,
              label: 'Categories',
              value: '${breakdown.categoryCount}',
              color: _gradientEnd,
            ),
            _MetricPill(
              icon: Icons.trending_up_rounded,
              label: 'Avg / entry',
              value: _formatCompact(breakdown.average),
              color: const Color(0xFFEC407A),
            ),
            if (top != null)
              _MetricPill(
                icon: top.category.icon,
                label: 'Top: ${top.category.label}',
                value: _formatCompact(top.total),
                color: top.category.color,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCards(CategoryBreakdown breakdown) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisExtent: 172,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final slice = breakdown.slices[index];
            return CategoryCard(
              slice: slice,
              formatValue: _formatCompact,
              selected: slice.category.id == _selectedCategoryId,
              onTap: () => _toggleSelection(
                slice.category.id == _selectedCategoryId ? null : slice.category.id,
              ),
            );
          },
          childCount: breakdown.slices.length,
        ),
      ),
    );
  }

  Widget _buildChartSection({
    required String title,
    required String subtitle,
    required Widget child,
    required CategoryBreakdown breakdown,
    bool showLegend = true,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              child,
              if (showLegend) ...[
                const SizedBox(height: 20),
                _Legend(
                  breakdown: breakdown,
                  selectedId: _selectedCategoryId,
                  formatValue: _formatCompact,
                  onSelected: _toggleSelection,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.type,
    required this.accent,
    required this.onChanged,
  });

  final ExpenseType type;
  final Color accent;
  final ValueChanged<ExpenseType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget segment(String label, IconData icon, ExpenseType value) {
      final selected = type == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          segment('Expenses', Icons.trending_down_rounded, ExpenseType.expense),
          segment('Income', Icons.trending_up_rounded, ExpenseType.income),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.breakdown,
    required this.selectedId,
    required this.formatValue,
    required this.onSelected,
  });

  final CategoryBreakdown breakdown;
  final String? selectedId;
  final String Function(double value) formatValue;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final slice in breakdown.slices)
          GestureDetector(
            onTap: () => onSelected(
              slice.category.id == selectedId ? null : slice.category.id,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: slice.category.id == selectedId
                    ? slice.category.color.withOpacity(0.16)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: slice.category.id == selectedId
                      ? slice.category.color
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: slice.category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    slice.category.label,
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatValue(slice.total),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
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

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics({required this.type});

  final ExpenseType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.donut_large_rounded,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              type == ExpenseType.income ? 'No income yet' : 'No expenses yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some ${type == ExpenseType.income ? 'income' : 'expenses'} with categories to see your breakdown here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
