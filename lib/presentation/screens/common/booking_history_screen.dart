import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/empty_state_view.dart';
import 'package:labour_link/data/models/job_session.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/recruiter_provider.dart';
import 'package:labour_link/presentation/providers/seeker_provider.dart';
import 'package:labour_link/presentation/screens/recruiter/job_session_screen.dart';
import 'package:provider/provider.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isSeeker = user?.isSeeker ?? false;

    final List<JobSession> sessions;
    final bool isLoading;
    if (isSeeker) {
      final provider = context.watch<SeekerProvider>();
      sessions = provider.sessions;
      isLoading = provider.isLoading && sessions.isEmpty;
    } else {
      final provider = context.watch<RecruiterProvider>();
      sessions = provider.mySessions;
      isLoading = provider.isLoading && sessions.isEmpty;
    }

    final pending = sessions
        .where((s) =>
            s.isPending ||
            s.status == 'session_created' ||
            s.isStarted ||
            s.isAwaitingPayment)
        .toList();
    final completed =
        sessions.where((s) => s.isCompleted || s.isPaid).toList();
    final cancelled =
        sessions.where((s) => s.status == 'cancelled').toList();

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded,
                        color: AppTheme.primary, size: 26),
                    const SizedBox(width: 12),
                    Text(
                      isSeeker ? 'My Job History' : 'Hired Workers History',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onBackground,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${sessions.length} total',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.subtle,
                indicatorColor: AppTheme.primary,
                tabs: [
                  Tab(text: 'All (${sessions.length})'),
                  Tab(text: 'Pending (${pending.length})'),
                  Tab(text: 'Completed (${completed.length})'),
                  Tab(text: 'Cancelled (${cancelled.length})'),
                ],
              ),
              const Divider(height: 1, color: Color(0xFF2A2A4A)),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _SessionList(
                            sessions: sessions,
                            isSeeker: isSeeker,
                          ),
                          _SessionList(
                            sessions: pending,
                            isSeeker: isSeeker,
                            emptyTitle: 'No pending jobs',
                            emptySubtitle:
                                'Active and awaiting-payment jobs appear here',
                          ),
                          _SessionList(
                            sessions: completed,
                            isSeeker: isSeeker,
                            emptyTitle: 'No completed jobs',
                            emptySubtitle:
                                'Finished and paid jobs will show here',
                          ),
                          _SessionList(
                            sessions: cancelled,
                            isSeeker: isSeeker,
                            emptyTitle: 'No cancelled jobs',
                            emptySubtitle: 'Cancelled jobs appear here',
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

class _SessionList extends StatelessWidget {
  const _SessionList({
    required this.sessions,
    required this.isSeeker,
    this.emptyTitle = 'No jobs here',
    this.emptySubtitle = 'Jobs will appear once created',
  });

  final List<JobSession> sessions;
  final bool isSeeker;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return EmptyStateView(
        icon: Icons.history_rounded,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _HistoryCard(
        session: sessions[i],
        isSeeker: isSeeker,
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.session, required this.isSeeker});
  final JobSession session;
  final bool isSeeker;

  Color _statusColor(String status) {
    switch (status) {
      case 'started':
        return AppTheme.warning;
      case 'awaiting_payment':
        return const Color(0xFF8B5CF6);
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.danger;
      default:
        return AppTheme.subtle;
    }
  }

  String _statusLabel(String status, String paymentStatus) {
    if (paymentStatus == 'paid' || paymentStatus == 'done') {
      return 'Paid ✓';
    }
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'session_created':
        return 'Session Ready';
      case 'started':
        return 'In Progress';
      case 'awaiting_payment':
        return 'Awaiting Payment';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _paymentMethodLabel() {
    if (session.isPaid) {
      return switch (session.paymentMethod.toLowerCase()) {
        'bank' => 'Bank Transfer',
        'cash' => 'Cash',
        _ => 'UPI',
      };
    }
    if (session.isPaymentPending) return 'Payment pending';
    return '—';
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('d MMM yyyy, h:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(session.status);
    final label = _statusLabel(session.status, session.paymentStatus);
    final otherName =
        isSeeker ? session.recruiterName : session.workerName;
    final otherLabel = isSeeker ? 'Recruiter' : 'Worker';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobSessionScreen(session: session),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      otherName.isNotEmpty
                          ? otherName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.onBackground,
                        ),
                      ),
                      Text(
                        otherLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.subtle,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withAlpha(80)),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFF2A2A4A)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DetailChip(
                    icon: Icons.work_outline_rounded,
                    label: session.profession,
                  ),
                ),
                const SizedBox(width: 8),
                _DetailChip(
                  icon: Icons.payments_outlined,
                  label: _paymentMethodLabel(),
                  highlight: session.isPaid,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DetailChip(
                    icon: Icons.schedule_rounded,
                    label: _formatDate(session.createdAt),
                  ),
                ),
                if (session.amount > 0) ...[
                  const SizedBox(width: 8),
                  _DetailChip(
                    icon: Icons.currency_rupee_rounded,
                    label: '₹${session.amount}',
                    highlight: session.isPaid,
                  ),
                ],
              ],
            ),
            if (session.completedAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              _DetailChip(
                icon: Icons.check_circle_outline_rounded,
                label: 'Completed: ${_formatDate(session.completedAt)}',
                color: AppTheme.success,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    this.highlight = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool highlight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (highlight ? AppTheme.success : AppTheme.subtle);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c,
              fontWeight:
                  highlight ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
