import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/data/models/app_user.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 24,
  });

  final AppUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (user.profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.surfaceVariant,
        backgroundImage: NetworkImage(user.profileImageUrl),
        onBackgroundImageError: (exception, stackTrace) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primary.withAlpha(30),
      child: Text(
        user.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
