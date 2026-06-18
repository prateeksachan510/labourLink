import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/empty_state_view.dart';
import 'package:labour_link/data/models/scheduled_booking.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/scheduled_booking_provider.dart';
import 'package:provider/provider.dart';

class ScheduledBookingsScreen extends StatefulWidget {
  const ScheduledBookingsScreen({super.key});

  @override
  State<ScheduledBookingsScreen> createState() =>
      _ScheduledBookingsScreenState();
}

class _ScheduledBookingsScreenState extends State<ScheduledBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;
      final provider = context.read<ScheduledBookingProvider>();
      if (user.isSeeker) {
        provider.startWatchingForWorker(user.uid);
      } else {
        provider.startWatchingForRecruiter(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final provider = context.watch<ScheduledBookingProvider>();
    final isSeeker = user?.isSeeker ?? false;

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppTheme.primary, size: 26),
                    const SizedBox(width: 12),
                    const Text(
                      'Scheduled Bookings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TabBar(
                controller: _tabs,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.subtle,
                indicatorColor: AppTheme.primary,
                tabs: [
                  Tab(text: 'Upcoming (${provider.upcoming.length})'),
                  Tab(text: 'Past (${provider.past.length})'),
                ],
              ),
              const Divider(height: 1, color: Color(0xFF2A2A4A)),

              Expanded(
                child: provider.isLoading && provider.bookings.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _BookingList(
                            bookings: provider.upcoming,
                            isSeeker: isSeeker,
                          ),
                          _BookingList(
                            bookings: provider.past,
                            isSeeker: isSeeker,
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

// ── Booking List ──────────────────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  const _BookingList({required this.bookings, required this.isSeeker});
  final List<ScheduledBooking> bookings;
  final bool isSeeker;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const EmptyStateView(
        icon: Icons.calendar_today_rounded,
        title: 'No bookings here',
        subtitle: 'Scheduled bookings will appear here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) =>
          _BookingCard(booking: bookings[i], isSeeker: isSeeker),
    );
  }
}

// ── Booking Card ──────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.isSeeker});
  final ScheduledBooking booking;
  final bool isSeeker;

  Color _statusColor(String status) => switch (status) {
        'accepted' => AppTheme.success,
        'rejected' => AppTheme.danger,
        'cancelled' => AppTheme.subtle,
        'completed' => AppTheme.primary,
        _ => AppTheme.warning,
      };

  String _statusLabel(String status) => switch (status) {
        'accepted' => 'Accepted ✓',
        'rejected' => 'Rejected ✗',
        'cancelled' => 'Cancelled',
        'completed' => 'Completed',
        _ => 'Pending',
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    final statusLabel = _statusLabel(booking.status);
    final otherName =
        isSeeker ? booking.recruiterName : booking.workerName;

    final formattedDate = (() {
      try {
        final dt = DateTime.parse(booking.scheduledDate);
        return DateFormat('EEE, d MMM yyyy').format(dt);
      } catch (_) {
        return booking.scheduledDate;
      }
    })();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
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
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
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
                      booking.profession,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.subtle),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: statusColor.withAlpha(80)),
                ),
                child: Text(
                  statusLabel,
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

          // Date + time
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: const TextStyle(
                  color: AppTheme.onBackground,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.access_time_rounded,
                  size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                booking.scheduledTime,
                style: const TextStyle(
                  color: AppTheme.onBackground,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (booking.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.note_outlined,
                    size: 13, color: AppTheme.subtle),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking.notes,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.subtle),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Seeker accept/reject actions (only for pending upcoming)
          if (isSeeker && booking.isPending && booking.isUpcoming) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                    ),
                    onPressed: () async {
                      await context
                          .read<ScheduledBookingProvider>()
                          .rejectBooking(
                              booking.bookingId, booking.recruiterId);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                    ),
                    onPressed: () async {
                      await context
                          .read<ScheduledBookingProvider>()
                          .acceptBooking(
                              booking.bookingId, booking.recruiterId);
                    },
                  ),
                ),
              ],
            ),
          ],

          // Recruiter cancel action (pending only)
          if (!isSeeker && booking.isPending && booking.isUpcoming) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Cancel Booking'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                ),
                onPressed: () async {
                  await context
                      .read<ScheduledBookingProvider>()
                      .cancelBooking(booking.bookingId);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
