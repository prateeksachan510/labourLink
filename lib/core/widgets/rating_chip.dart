import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';

/// Compact chip showing "⭐ 4.2 (18)" for worker cards & profiles.
class RatingChip extends StatelessWidget {
  const RatingChip({
    super.key,
    required this.average,
    required this.count,
    this.compact = false,
  });

  final double average;
  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (average == 0 && count == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: const Text(
          'No ratings yet',
          style: TextStyle(fontSize: 11, color: AppTheme.subtle),
        ),
      );
    }
    final avgStr = average.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.warning.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppTheme.warning, size: 13),
          const SizedBox(width: 3),
          Text(
            compact ? avgStr : '$avgStr ($count)',
            style: const TextStyle(
              color: AppTheme.warning,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
