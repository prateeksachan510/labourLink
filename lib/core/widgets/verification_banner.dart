import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/data/models/app_user.dart';
import 'package:labour_link/presentation/screens/common/verification_center_screen.dart';

/// Reusable verification status banner shown on home screens when the user
/// is not yet verified. Provides contextual messaging and a CTA button to
/// navigate to the VerificationCenterScreen.
///
/// Pass [user] and the banner auto-hides when [user.isVerified] is true.
class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    // Hide banner for verified users
    if (user.isVerified) return const SizedBox.shrink();

    final (Color color, IconData icon, String message, String ctaLabel) =
        _resolve(user);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VerificationCenterScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withAlpha(100)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ctaLabel,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: color, size: 11),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static (Color, IconData, String, String) _resolve(AppUser user) {
    if (user.isVerificationRejected) {
      return (
        AppTheme.danger,
        Icons.cancel_outlined,
        'Your ID verification was rejected. Please re-upload a valid document.',
        'Re-upload ID',
      );
    }
    if (user.isVerificationPending) {
      return (
        AppTheme.warning,
        Icons.hourglass_top_rounded,
        'Verification under review — usually takes up to 24 hours. You can browse freely.',
        'View Status',
      );
    }
    // not_uploaded (empty status)
    return (
      AppTheme.warning,
      Icons.shield_outlined,
      'Upload your ID to unlock hiring & job acceptance features.',
      'Upload Now',
    );
  }
}
