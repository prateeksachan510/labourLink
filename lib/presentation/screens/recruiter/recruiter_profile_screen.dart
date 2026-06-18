import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/user_avatar.dart';
import 'package:labour_link/core/widgets/verified_badge.dart';
import 'package:labour_link/core/widgets/verification_banner.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/screens/common/verification_center_screen.dart';
import 'package:provider/provider.dart';

/// Recruiter profile: photo upload, verification, and account info.
class RecruiterProfileScreen extends StatefulWidget {
  const RecruiterProfileScreen({super.key});

  @override
  State<RecruiterProfileScreen> createState() => _RecruiterProfileScreenState();
}

class _RecruiterProfileScreenState extends State<RecruiterProfileScreen> {
  final _imagePicker = ImagePicker();

  Future<void> _editPhoto() async {
    final auth = context.read<AuthProvider>();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked == null) return;
      final ok = await auth.uploadProfilePhoto(picked);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Photo updated ✓' : (auth.error ?? 'Upload failed'),
          ),
          backgroundColor: ok ? AppTheme.success : AppTheme.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Could not update photo.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: user == null
              ? const Center(
                  child: Text(
                    'Profile not available',
                    style: TextStyle(color: AppTheme.subtle),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ── Profile Header ───────────────────────────────────
                    Row(
                      children: [
                        UserAvatar(user: user, radius: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onBackground,
                                ),
                              ),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.subtle,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (user.isVerified) const VerifiedBadge(),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: auth.isLoading ? null : _editPhoto,
                          icon: const Icon(
                            Icons.photo_camera_outlined,
                            color: AppTheme.primary,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primary.withAlpha(20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              context.read<AuthProvider>().logout(),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: AppTheme.danger,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.danger.withAlpha(20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Verification Banner ──────────────────────────────
                    VerificationBanner(user: user),

                    // ── Info Cards ───────────────────────────────────────
                    _InfoCard(
                      icon: Icons.work_outline,
                      label: 'Role',
                      value: 'Recruiter',
                    ),
                    const SizedBox(height: 10),
                    if (user.location.isNotEmpty)
                      _InfoCard(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: user.location,
                      ),
                    if (user.location.isNotEmpty) const SizedBox(height: 10),
                    if (user.phone.isNotEmpty)
                      _InfoCard(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: user.phone,
                      ),
                    if (user.phone.isNotEmpty) const SizedBox(height: 10),

                    // ── Verification Center Button ────────────────────────
                    const SizedBox(height: 8),
                    _VerificationStatusCard(
                      status: user.verificationStatus,
                      idType: user.idType,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VerificationCenterScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.subtle)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onBackground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerificationStatusCard extends StatelessWidget {
  const _VerificationStatusCard({
    required this.status,
    required this.idType,
    required this.onTap,
  });

  final String status;
  final String idType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon, String label) = switch (
        status.toLowerCase()) {
      'verified' => (AppTheme.success, Icons.verified_rounded, 'Verified'),
      'pending' => (AppTheme.warning, Icons.hourglass_top_rounded, 'Pending'),
      'rejected' => (AppTheme.danger, Icons.cancel_outlined, 'Rejected'),
      _ => (AppTheme.subtle, Icons.shield_outlined, 'Not Verified'),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ID Verification',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.subtle,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (idType.isNotEmpty)
                    Text(
                      'ID: $idType',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.subtle),
                    ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status.toLowerCase() == 'verified'
                        ? 'View'
                        : 'Open',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: color, size: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
