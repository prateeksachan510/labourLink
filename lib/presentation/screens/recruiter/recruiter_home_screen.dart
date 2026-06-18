import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/app_card.dart';
import 'package:labour_link/core/widgets/verification_banner.dart';
import 'package:labour_link/core/widgets/verified_badge.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/recruiter_provider.dart';
import 'package:labour_link/presentation/screens/recruiter/worker_list_screen.dart';
import 'package:provider/provider.dart';

class RecruiterHomeScreen extends StatelessWidget {
  const RecruiterHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                user?.initials ?? 'R',
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
                                const Text(
                                  'Find and hire skilled workers',
                                  style: TextStyle(
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
                      const SizedBox(height: 28),
                      if (user != null) VerificationBanner(user: user),
                      const Text(
                        'Browse by Profession',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.25,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final profession =
                          RecruiterProvider.professions[index];
                      final icon = RecruiterProvider.professionIcons[profession]
                          ?? Icons.work_outline;
                      return _ProfessionGridTile(
                        profession: profession,
                        icon: icon,
                        index: index,
                      );
                    },
                    childCount: RecruiterProvider.professions.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfessionGridTile extends StatelessWidget {
  const _ProfessionGridTile({
    required this.profession,
    required this.icon,
    required this.index,
  });

  final String profession;
  final IconData icon;
  final int index;

  static const _gradients = [
    AppTheme.primaryGradient,
    LinearGradient(
      colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFC5C7D), Color(0xFF6A3093)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFf7971e), Color(0xFFffd200)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF43C6AC), Color(0xFF191654)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFDA22FF), Color(0xFF9733EE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFf953c6), Color(0xFFb91d73)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[index % _gradients.length];
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerListScreen(profession: profession),
        ),
      ),
      padding: const EdgeInsets.all(0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              profession,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
