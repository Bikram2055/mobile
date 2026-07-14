import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/category_analytics.dart';

/// An animated, tappable doughnut chart. Tapping a slice selects it and shows
/// its total in the center; tapping the same slice again clears the selection.
class DoughnutChart extends StatefulWidget {
  const DoughnutChart({
    super.key,
    required this.slices,
    required this.total,
    required this.centerLabel,
    required this.formatValue,
    this.selectedId,
    this.onSelected,
    this.size = 240,
  });

  final List<CategorySlice> slices;
  final double total;
  final String centerLabel;
  final String Function(double value) formatValue;
  final String? selectedId;
  final ValueChanged<String?>? onSelected;
  final double size;

  @override
  State<DoughnutChart> createState() => _DoughnutChartState();
}

class _DoughnutChartState extends State<DoughnutChart>
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(Offset localPosition) {
    if (widget.onSelected == null || widget.total <= 0) {
      return;
    }
    final center = Offset(widget.size / 2, widget.size / 2);
    final vector = localPosition - center;
    final distance = vector.distance;
    final outer = widget.size / 2;
    final inner = outer * 0.58;
    if (distance < inner * 0.75 || distance > outer) {
      widget.onSelected!(null);
      return;
    }

    // Angle measured clockwise from the top (12 o'clock), matching the painter.
    double angle = math.atan2(vector.dy, vector.dx) + math.pi / 2;
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    double sweepStart = 0;
    for (final slice in widget.slices) {
      final sweep = (slice.total / widget.total) * 2 * math.pi;
      if (angle >= sweepStart && angle < sweepStart + sweep) {
        final next = slice.category.id == widget.selectedId ? null : slice.category.id;
        widget.onSelected!(next);
        return;
      }
      sweepStart += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.slices.where((s) => s.category.id == widget.selectedId);
    final CategorySlice? active = selected.isEmpty ? null : selected.first;

    final centerValue = active != null ? active.total : widget.total;
    final centerTitle = active != null ? active.category.label : widget.centerLabel;

    return GestureDetector(
      onTapUp: (details) => _handleTap(details.localPosition),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _DoughnutPainter(
                slices: widget.slices,
                total: widget.total,
                progress: Curves.easeOutCubic.transform(_controller.value),
                selectedId: widget.selectedId,
                trackColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: active?.category.color ?? theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.formatValue(centerValue),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (active != null)
                      Text(
                        '${(active.share * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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

class _DoughnutPainter extends CustomPainter {
  _DoughnutPainter({
    required this.slices,
    required this.total,
    required this.progress,
    required this.selectedId,
    required this.trackColor,
  });

  final List<CategorySlice> slices;
  final double total;
  final double progress;
  final String? selectedId;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final ringWidth = outerRadius * 0.30;
    final radius = outerRadius - ringWidth / 2;

    // Background track.
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    if (total <= 0) {
      return;
    }

    const startAngle = -math.pi / 2; // 12 o'clock
    double sweepStart = startAngle;
    const gap = 0.03; // radians of spacing between slices

    for (final slice in slices) {
      final fullSweep = (slice.total / total) * 2 * math.pi;
      final sweep = (fullSweep - gap).clamp(0.0, 2 * math.pi) * progress;
      final selected = slice.category.id == selectedId;
      final dimmed = selectedId != null && !selected;

      final thickness = selected ? ringWidth + 8 : ringWidth;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = thickness
        ..color = dimmed ? slice.category.color.withOpacity(0.28) : slice.category.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        sweepStart,
        sweep,
        false,
        paint,
      );
      sweepStart += fullSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DoughnutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.total != total ||
        oldDelegate.slices != slices;
  }
}
