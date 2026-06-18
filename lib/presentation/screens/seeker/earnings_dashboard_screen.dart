import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/data/models/earnings_summary.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/earnings_provider.dart';
import 'package:provider/provider.dart';

class EarningsDashboardScreen extends StatefulWidget {
  const EarningsDashboardScreen({super.key});

  @override
  State<EarningsDashboardScreen> createState() =>
      _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState extends State<EarningsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid != null) {
        context.read<EarningsProvider>().loadEarnings(uid);
      }
    });
  }

  Future<void> _refresh() async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid != null) {
      await context.read<EarningsProvider>().refresh(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EarningsProvider>();
    final summary = provider.summary;

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppTheme.primary,
            backgroundColor: AppTheme.surface,
            child: CustomScrollView(
              slivers: [
                // ── App Bar ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppTheme.onBackground),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.surfaceVariant,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Earnings Dashboard',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.onBackground,
                                ),
                              ),
                              Text(
                                'Pull down to refresh',
                                style: TextStyle(
                                    fontSize: 12, color: AppTheme.subtle),
                              ),
                            ],
                          ),
                        ),
                        if (provider.isLoading)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.primary),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Total earnings hero ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _HeroCard(summary: summary),
                  ),
                ),

                // ── Stats row ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'This Month',
                            value: '₹${_fmt(summary.monthlyEarnings)}',
                            icon: Icons.calendar_month_rounded,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'This Week',
                            value: '₹${_fmt(summary.weeklyEarnings)}',
                            icon: Icons.date_range_rounded,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Jobs + Pending + Rating row ────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Jobs Done',
                            value: '${summary.completedJobs}',
                            icon: Icons.check_circle_rounded,
                            color: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Pending Pay',
                            value: '${summary.pendingPayments}',
                            icon: Icons.hourglass_top_rounded,
                            color: const Color(0xFF8B5CF6),
                            subtitle: 'Awaiting payment',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _StatCard(
                      label: 'Avg Rating',
                      value: summary.averageRating > 0
                          ? '⭐ ${summary.averageRating.toStringAsFixed(1)}'
                          : '—',
                      icon: Icons.star_rounded,
                      color: AppTheme.warning,
                      subtitle: summary.ratingCount > 0
                          ? '${summary.ratingCount} reviews'
                          : null,
                    ),
                  ),
                ),

                // ── Recent payments ────────────────────────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'Recent Payments',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onBackground,
                      ),
                    ),
                  ),
                ),

                if (summary.recentPayments.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Center(
                        child: Text(
                          'No payments yet.\nComplete jobs to see your earnings here.',
                          style: TextStyle(color: AppTheme.subtle),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _PaymentTile(
                          payment: summary.recentPayments[i],
                        ),
                        childCount: summary.recentPayments.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(int amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toString();
  }
}

// ── Hero Card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary});
  final EarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'Total Earnings',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${summary.totalEarnings.toString()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.lastUpdated.isNotEmpty
                ? 'Last updated: ${_formatDate(summary.lastUpdated)}'
                : 'Pull down to refresh',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('d MMM, h:mm a').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.onBackground,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.subtle),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.subtle),
            ),
        ],
      ),
    );
  }
}

// ── Payment Tile ──────────────────────────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});
  final RecentPayment payment;

  String _formatDate(String iso) {
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.success.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.currency_rupee_rounded,
                color: AppTheme.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.recruiterName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.onBackground,
                  ),
                ),
                Text(
                  '${payment.profession} · ${_formatDate(payment.paidAt)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.subtle),
                ),
              ],
            ),
          ),
          Text(
            '₹${payment.amount}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }
}
