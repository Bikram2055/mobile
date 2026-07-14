import 'package:flutter/material.dart';

import '../../domain/category_analytics.dart';

/// A compact, tappable summary card for one category. Selecting it highlights
/// the matching slice across every chart on the screen.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.slice,
    required this.formatValue,
    required this.selected,
    required this.onTap,
  });

  final CategorySlice slice;
  final String Function(double value) formatValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = slice.category.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? [color.withOpacity(0.22), color.withOpacity(0.08)]
                : [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface,
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (selected ? color : theme.colorScheme.shadow).withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(slice.category.icon, size: 18, color: color),
                ),
                const Spacer(),
                Text(
                  '${(slice.share * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              slice.category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatValue(slice.total),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: slice.share.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: color.withOpacity(0.14),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${slice.count} ${slice.count == 1 ? 'entry' : 'entries'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
