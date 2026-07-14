import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/category_analytics.dart';

/// An animated vertical bar chart with one bar per category. Tapping a bar
/// selects it; the selected bar shows its value on top.
class CategoryBarChart extends StatefulWidget {
  const CategoryBarChart({
    super.key,
    required this.slices,
    required this.formatValue,
    this.selectedId,
    this.onSelected,
    this.height = 220,
  });

  final List<CategorySlice> slices;
  final String Function(double value) formatValue;
  final String? selectedId;
  final ValueChanged<String?>? onSelected;
  final double height;

  @override
  State<CategoryBarChart> createState() => _CategoryBarChartState();
}

class _CategoryBarChartState extends State<CategoryBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant CategoryBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slices.length != widget.slices.length) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slices = widget.slices;
    if (slices.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No data to chart',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final maxValue = slices.map((s) => s.total).reduce(math.max);
    const barSlotWidth = 64.0;

    return SizedBox(
      height: widget.height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = Curves.easeOutCubic.transform(_controller.value);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final slice in slices)
                  _Bar(
                    slice: slice,
                    maxValue: maxValue,
                    progress: progress,
                    width: barSlotWidth,
                    selected: slice.category.id == widget.selectedId,
                    dimmed: widget.selectedId != null &&
                        slice.category.id != widget.selectedId,
                    label: widget.formatValue(slice.total),
                    onTap: () {
                      widget.onSelected?.call(
                        slice.category.id == widget.selectedId
                            ? null
                            : slice.category.id,
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.slice,
    required this.maxValue,
    required this.progress,
    required this.width,
    required this.selected,
    required this.dimmed,
    required this.label,
    required this.onTap,
  });

  final CategorySlice slice;
  final double maxValue;
  final double progress;
  final double width;
  final bool selected;
  final bool dimmed;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const trackHeight = 150.0;
    final fraction = maxValue <= 0 ? 0.0 : (slice.total / maxValue);
    final barHeight = (trackHeight * fraction * progress).clamp(4.0, trackHeight);
    final color = slice.category.color;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: 18,
              child: (selected || fraction > 0.55)
                  ? FittedBox(
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 34 : 28,
              height: barHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(dimmed ? 0.35 : 1),
                    color.withOpacity(dimmed ? 0.2 : 0.55),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(selected ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                slice.category.icon,
                size: 16,
                color: color.withOpacity(dimmed ? 0.5 : 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
