import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.success.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.success.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 14,
            color: AppTheme.success,
          ),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              color: AppTheme.success,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
