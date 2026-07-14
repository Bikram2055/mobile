import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/category_analytics.dart';

/// A radial (concentric) bar chart: each category is a ring whose arc length is
/// proportional to its value relative to the largest category. Tapping a ring
/// selects it.
class RadialBarChart extends StatefulWidget {
  const RadialBarChart({
    super.key,
    required this.slices,
    required this.formatValue,
    this.selectedId,
    this.onSelected,
    this.maxRings = 6,
    this.size = 240,
  });

  final List<CategorySlice> slices;
  final String Function(double value) formatValue;
  final String? selectedId;
  final ValueChanged<String?>? onSelected;
  final int maxRings;
  final double size;

  @override
  State<RadialBarChart> createState() => _RadialBarChartState();
}

class _RadialBarChartState extends State<RadialBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<CategorySlice> get _rings =>
      widget.slices.take(widget.maxRings).toList(growable: false);

  void _handleTap(Offset localPosition) {
    final rings = _rings;
    if (widget.onSelected == null || rings.isEmpty) {
      return;
    }
    final center = Offset(widget.size / 2, widget.size / 2);
    final distance = (localPosition - center).distance;

    final outerRadius = widget.size / 2;
    const minRadius = 26.0;
    final band = (outerRadius - minRadius) / rings.length;

    for (var i = 0; i < rings.length; i++) {
      final ringRadius = outerRadius - band * i - band / 2;
      if ((distance - ringRadius).abs() <= band / 2) {
        final id = rings[i].category.id;
        widget.onSelected!(id == widget.selectedId ? null : id);
        return;
      }
    }
    widget.onSelected!(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rings = _rings;
    final maxValue = rings.isEmpty
        ? 0.0
        : rings.map((s) => s.total).reduce(math.max);

    return GestureDetector(
      onTapUp: (details) => _handleTap(details.localPosition),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _RadialBarPainter(
                rings: rings,
                maxValue: maxValue,
                progress: Curves.easeOutCubic.transform(_controller.value),
                selectedId: widget.selectedId,
                trackColor: theme.colorScheme.surfaceVariant.withOpacity(0.45),
              ),
              child: rings.isEmpty
                  ? Center(
                      child: Text(
                        'No data',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _RadialBarPainter extends CustomPainter {
  _RadialBarPainter({
    required this.rings,
    required this.maxValue,
    required this.progress,
    required this.selectedId,
    required this.trackColor,
  });

  final List<CategorySlice> rings;
  final double maxValue;
  final double progress;
  final String? selectedId;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (rings.isEmpty || maxValue <= 0) {
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    const minRadius = 26.0;
    final band = (outerRadius - minRadius) / rings.length;
    final strokeWidth = band * 0.66;
    const startAngle = -math.pi / 2;
    const maxSweep = 1.75 * math.pi; // leave a small gap so rings read as bars

    for (var i = 0; i < rings.length; i++) {
      final slice = rings[i];
      final ringRadius = outerRadius - band * i - band / 2;
      final selected = slice.category.id == selectedId;
      final dimmed = selectedId != null && !selected;

      // Track for this ring.
      final trackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = trackColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle,
        maxSweep,
        false,
        trackPaint,
      );

      final fraction = (slice.total / maxValue).clamp(0.0, 1.0);
      final sweep = maxSweep * fraction * progress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = selected ? strokeWidth + 4 : strokeWidth
        ..shader = LinearGradient(
          colors: [
            slice.category.color.withOpacity(dimmed ? 0.3 : 0.75),
            slice.category.color.withOpacity(dimmed ? 0.4 : 1),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: ringRadius));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadialBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.rings != rings;
  }
}
