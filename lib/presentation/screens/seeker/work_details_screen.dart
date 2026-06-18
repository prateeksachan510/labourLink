import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class WorkDetailsScreen extends StatelessWidget {
  const WorkDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
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
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Work Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                  ),
                ),
                const SizedBox(height: 20),
                if (user == null)
                  const Center(
                    child: Text(
                      'Profile not found',
                      style: TextStyle(color: AppTheme.subtle),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2A2A4A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.profession.isNotEmpty
                              ? user.profession
                              : 'No profession set',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          icon: Icons.person_outline,
                          label: 'Name',
                          value: user.name,
                        ),
                        _DetailRow(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: user.location,
                        ),
                        _DetailRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: user.phone,
                        ),
                        const Divider(height: 24),
                        Text(
                          user.bio.isNotEmpty ? user.bio : 'No bio provided.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.subtle),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: AppTheme.subtle),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onBackground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

