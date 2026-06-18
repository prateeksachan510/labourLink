import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/app_card.dart';
import 'package:labour_link/core/widgets/status_badge.dart';
import 'package:labour_link/core/widgets/verification_banner.dart';
import 'package:labour_link/core/widgets/verified_badge.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/seeker_provider.dart';
import 'package:labour_link/presentation/screens/seeker/otp_confirm_screen.dart';
import 'package:provider/provider.dart';

class SeekerHomeScreen extends StatelessWidget {
  const SeekerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final seeker = context.watch<SeekerProvider>();

    final pending = seeker.requests.where((r) => r.status == 'pending').length;
    final accepted =
        seeker.requests.where((r) => r.status == 'accepted').length;
    // Sessions where OTP needs to be entered (recruiter started the session).
    final activeSessions = seeker.sessions
        .where((s) => s.isPending || s.status == 'session_created')
        .toList();
    // Sessions already in progress.
    final inProgressSessions =
        seeker.sessions.where((s) => s.isStarted).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          user?.initials ?? '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.name.split(' ').first ?? ''}! 👋',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onBackground,
                            ),
                          ),
                          Text(
                            user?.profession.isNotEmpty == true
                                ? user!.profession
                                : 'Complete your profile',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.subtle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (user?.isVerified == true)
                            const VerifiedBadge(compact: true),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (user != null) VerificationBanner(user: user),

                // Stats Row
                Row(
                  children: [
                    _StatCard(
                      label: 'Pending',
                      value: pending.toString(),
                      icon: Icons.hourglass_empty_rounded,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Accepted',
                      value: accepted.toString(),
                      icon: Icons.check_circle_outline,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Sessions',
                      value: seeker.sessions.length.toString(),
                      icon: Icons.work_outline,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Active Sessions
                if (activeSessions.isNotEmpty) ...[
                  const Text(
                    'Active Sessions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...activeSessions.map(
                    (session) => AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.key_rounded,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.recruiterName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onBackground,
                                      ),
                                    ),
                                    Text(
                                      session.profession,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.subtle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(status: session.status),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.key_rounded, size: 16),
                              label: const Text('Enter OTP to Start'),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OtpConfirmScreen(session: session),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Jobs In Progress
                if (inProgressSessions.isNotEmpty) ...[
                  const Text(
                    'Jobs In Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...inProgressSessions.map(
                    (session) => AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.work_rounded,
                                  color: AppTheme.success,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.recruiterName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onBackground,
                                      ),
                                    ),
                                    Text(
                                      session.profession,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.subtle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(status: session.status),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                  Icons.task_alt_rounded,
                                  size: 16),
                              label: const Text('Mark as Complete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                              ),
                              onPressed: () => context.read<SeekerProvider>().completeJob(
                                    jobId: session.jobId,
                                    workerId: session.workerId,
                                    recruiterId: session.recruiterId,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Profession card
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withAlpha(30),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Profession',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.subtle,
                              ),
                            ),
                            Text(
                              user?.profession.isNotEmpty == true
                                  ? user!.profession
                                  : 'Not set',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}


class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.subtle),
            ),
          ],
        ),
      ),
    );
  }
}
