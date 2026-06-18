import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';

/// Interactive or read-only star rating bar.
/// Set [interactive] = true to allow user selection.
class StarRatingBar extends StatefulWidget {
  const StarRatingBar({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.interactive = false,
    this.starSize = 28.0,
    this.activeColor = AppTheme.warning,
    this.inactiveColor = const Color(0xFF3A3A5A),
  });

  final double rating;
  final ValueChanged<int>? onRatingChanged;
  final bool interactive;
  final double starSize;
  final Color activeColor;
  final Color inactiveColor;

  @override
  State<StarRatingBar> createState() => _StarRatingBarState();
}

class _StarRatingBarState extends State<StarRatingBar> {
  late double _current;

  @override
  void initState() {
    super.initState();
    _current = widget.rating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final filled = _current >= starValue;
        final halfFilled = !filled && _current >= starValue - 0.5;
        return GestureDetector(
          onTap: widget.interactive
              ? () {
                  setState(() => _current = starValue.toDouble());
                  widget.onRatingChanged?.call(starValue);
                }
              : null,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              filled
                  ? Icons.star_rounded
                  : halfFilled
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              key: ValueKey('$index-$_current'),
              color: filled || halfFilled
                  ? widget.activeColor
                  : widget.inactiveColor,
              size: widget.starSize,
            ),
          ),
        );
      }),
    );
  }
}
