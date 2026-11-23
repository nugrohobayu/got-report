import 'package:flutter/material.dart';
import 'package:got_report/core/theme/app_colors.dart';

enum StepBarPhase { pending, active, done, error }

class StepBarItem {
  /// Short label under the circle.
  final String label;
  final StepBarPhase phase;

  /// Shown instead of the number (e.g. a pen for the signature step).
  final IconData? icon;

  const StepBarItem({required this.label, required this.phase, this.icon});
}

/// Horizontal stepper: numbered circles with a short label below, joined by
/// thin lines. Fills the width when the steps fit; otherwise scrolls and
/// keeps the active step in view.
class StepBar extends StatefulWidget {
  final List<StepBarItem> steps;

  const StepBar({super.key, required this.steps});

  @override
  State<StepBar> createState() => _StepBarState();
}

class _StepBarState extends State<StepBar> {
  static const _itemWidth = 64.0;
  static const _minLine = 20.0;
  final _activeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _revealActive();
  }

  @override
  void didUpdateWidget(StepBar old) {
    super.didUpdateWidget(old);
    _revealActive();
  }

  void _revealActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _activeKey.currentContext;
      // Only scrolls when the bar is in its scrolling layout.
      if (ctx == null || !mounted || Scrollable.maybeOf(ctx) == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
      );
    });
  }

  int get _focusIndex {
    final steps = widget.steps;
    final i = steps.indexWhere(
        (s) => s.phase == StepBarPhase.active || s.phase == StepBarPhase.error);
    if (i >= 0) return i;
    final lastDone = steps.lastIndexWhere((s) => s.phase == StepBarPhase.done);
    return lastDone < 0 ? 0 : lastDone;
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    if (steps.isEmpty) return const SizedBox.shrink();
    final focus = _focusIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        final n = steps.length;
        final fits =
            n * _itemWidth + (n - 1) * _minLine <= constraints.maxWidth;

        final children = <Widget>[];
        for (var i = 0; i < n; i++) {
          if (i > 0) {
            final line = _Line(done: steps[i - 1].phase == StepBarPhase.done);
            children.add(fits
                ? Expanded(child: line)
                : SizedBox(width: _minLine, child: line));
          }
          children.add(
            SizedBox(
              key: i == focus ? _activeKey : null,
              width: _itemWidth,
              child: _Item(number: i + 1, data: steps[i]),
            ),
          );
        }

        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
        if (fits) return row;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: row,
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  final bool done;

  const _Line({required this.done});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 2,
      // Centered on the 28 px circle; the item width already gives spacing.
      margin: const EdgeInsets.only(top: 13),
      decoration: BoxDecoration(
        color: done ? scheme.primary : scheme.outline,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final int number;
  final StepBarItem data;

  const _Item({required this.number, required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.7);
    const size = 28.0;
    final pending = data.phase == StepBarPhase.pending;

    Widget symbol(Color color) => data.icon != null
        ? Icon(data.icon, size: 15, color: color)
        : Text(
            '$number',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          );

    final (Color fill, Color border, Widget child) = switch (data.phase) {
      StepBarPhase.done => (
          scheme.primary,
          scheme.primary,
          const Icon(Icons.check_rounded, size: 16, color: Colors.white),
        ),
      StepBarPhase.error => (
          scheme.error,
          scheme.error,
          const Icon(Icons.priority_high_rounded,
              size: 16, color: Colors.white),
        ),
      StepBarPhase.active => (
          AppColors.statusSelesai,
          AppColors.statusSelesai,
          symbol(Colors.white),
        ),
      StepBarPhase.pending => (scheme.surface, scheme.outline, symbol(muted)),
    };

    final labelColor = switch (data.phase) {
      StepBarPhase.pending => muted,
      StepBarPhase.error => scheme.error,
      StepBarPhase.active => AppColors.statusSelesai,
      StepBarPhase.done => scheme.primary,
    };

    return Semantics(
      label: 'Langkah $number: ${data.label}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: border, width: 2),
            ),
            child: child,
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: pending ? FontWeight.w500 : FontWeight.w600,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
