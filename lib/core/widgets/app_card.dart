import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A4A), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: AppTheme.primary.withAlpha(30),
          highlightColor: AppTheme.primary.withAlpha(15),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
