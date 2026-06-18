import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/presentation/screens/auth/register_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                const SizedBox(height: 32),
                const Text(
                  'Join as',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose your role to get started',
                  style: TextStyle(fontSize: 15, color: AppTheme.subtle),
                ),
                const SizedBox(height: 40),
                _RoleCard(
                  title: 'Worker',
                  subtitle:
                      'Find job opportunities, accept hiring requests, and grow your career',
                  icon: Icons.construction_rounded,
                  gradient: AppTheme.primaryGradient,
                  role: 'Seeker',
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  title: 'Recruiter',
                  subtitle:
                      'Browse skilled workers, hire by profession, and manage your workforce',
                  icon: Icons.business_center_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  role: 'Recruiter',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.role,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final String role;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RegisterScreen(role: role)),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.subtle,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.subtle,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

