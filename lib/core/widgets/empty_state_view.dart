import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    this.message,
    this.icon,
    this.title,
    this.subtitle,
  }) : assert(
          message != null || title != null,
          'Provide either message or title',
        );

  final String? message;
  final IconData? icon;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    // Legacy: if only message is provided, render simple text
    if (title == null && icon == null) {
      return Center(
        child: Text(
          message ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: AppTheme.primary),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              title ?? message ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.subtle,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
