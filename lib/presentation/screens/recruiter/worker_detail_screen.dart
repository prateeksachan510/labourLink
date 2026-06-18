import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/gradient_button.dart';
import 'package:labour_link/core/widgets/user_avatar.dart';
import 'package:labour_link/core/widgets/verification_banner.dart';
import 'package:labour_link/core/widgets/verified_badge.dart';
import 'package:labour_link/data/models/app_user.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/recruiter_provider.dart';
import 'package:labour_link/presentation/screens/recruiter/schedule_booking_screen.dart';
import 'package:labour_link/presentation/screens/recruiter/worker_certificates_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerDetailScreen extends StatelessWidget {
  const WorkerDetailScreen({super.key, required this.worker});
  final AppUser worker;

  Future<void> _callWorker(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final recruiter = auth.currentUser;
    final provider = context.watch<RecruiterProvider>();
    final isRecruiterVerified = recruiter?.isVerified ?? false;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.onBackground,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Worker hero
                Center(
                  child: Column(
                    children: [
                      UserAvatar(user: worker, radius: 48),
                      const SizedBox(height: 16),
                      Text(
                        worker.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (worker.isVerified) const VerifiedBadge(),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary.withAlpha(60),
                          ),
                        ),
                        child: Text(
                          worker.profession,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Info cards
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: worker.location,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: worker.phone,
                ),
                const SizedBox(height: 20),

                // Bio
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2A4A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.subtle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        worker.bio.isNotEmpty ? worker.bio : 'No bio provided.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Action buttons
                if (provider.isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                else ...[
                  if (recruiter != null && !isRecruiterVerified)
                    VerificationBanner(user: recruiter),
                  GradientButton(
                    label: 'Hire Now',
                    icon: Icons.handshake_outlined,
                    isLoading: provider.isLoading,
                    onPressed: recruiter == null
                        ? null
                        : !isRecruiterVerified
                        ? null
                        : () async {
                            debugPrint(
                              '[WorkerDetailScreen] hire tap uid=${recruiter.uid} '
                              'workerId=${worker.uid} recruiterId=${recruiter.uid}',
                            );
                            final success = await context
                                .read<RecruiterProvider>()
                                .hireWorker(
                                  recruiterId: recruiter.uid,
                                  recruiterName: recruiter.name,
                                  worker: worker,
                                  address: worker.location,
                                );
                            if (!context.mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '✓ Hire request sent! Go to My Hires to track it.',
                                  ),
                                ),
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.read<RecruiterProvider>().error ??
                                        'Failed to hire',
                                  ),
                                  backgroundColor: AppTheme.danger,
                                ),
                              );
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  // Schedule Booking
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text('Schedule Booking'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                    ),
                    onPressed: recruiter == null || !isRecruiterVerified
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ScheduleBookingScreen(worker: worker),
                              ),
                            ),
                  ),
                  const SizedBox(height: 12),
                  // View Certificates
                  OutlinedButton.icon(
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text('View Certificates'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      foregroundColor: AppTheme.secondary,
                      side: const BorderSide(color: AppTheme.secondary),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WorkerCertificatesScreen(worker: worker),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.phone_outlined),
                    label: const Text('Call Worker'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    onPressed: () => _callWorker(worker.phone),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.subtle),
              ),
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
