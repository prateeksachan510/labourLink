import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/app_card.dart';
import 'package:labour_link/core/widgets/empty_state_view.dart';
import 'package:labour_link/core/widgets/status_badge.dart';
import 'package:labour_link/data/models/hiring_request.dart';
import 'package:labour_link/data/models/job_session.dart';
import 'package:labour_link/domain/repositories/chat_repository.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/chat_provider.dart';
import 'package:labour_link/presentation/providers/recruiter_provider.dart';
import 'package:labour_link/presentation/screens/common/chat_screen.dart';
import 'package:labour_link/presentation/screens/common/rate_user_dialog.dart';
import 'package:labour_link/presentation/screens/recruiter/job_session_screen.dart';
import 'package:provider/provider.dart';

/// STEP 4 & 5 — Recruiter views accepted workers and starts work sessions.
class MyHiresScreen extends StatelessWidget {
  const MyHiresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recruiter = context.watch<RecruiterProvider>();
    final currentUser = context.watch<AuthProvider>().currentUser;
    final uid = currentUser?.uid;
    final isVerified = currentUser?.isVerified ?? false;
    final visibleHires = recruiter.myHires
        .where((h) =>
            h.status == 'accepted' ||
            h.status == 'session_created' ||
            h.status == 'started' ||
            h.status == 'awaiting_payment' ||
            h.status == 'completed')
        .toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Hires',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onBackground,
                          ),
                        ),
                        Text(
                          '${visibleHires.length} total',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.subtle,
                          ),
                        ),
                      ],
                    ),
                    // Live badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.success.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Live',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: uid == null
                    ? const EmptyStateView(message: 'Not signed in')
                    : visibleHires.isEmpty
                        ? const EmptyStateView(
                            message:
                                'No hires yet.\nHire workers from the Home tab.')
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: visibleHires.length,
                            itemBuilder: (context, index) {
                              final hire = visibleHires[index];
                              final session = recruiter.sessionForHire(hire);
                              return _HireCard(
                                hire: hire,
                                session: session,
                                isVerified: isVerified,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _HireCard extends StatelessWidget {
  const _HireCard({
    required this.hire,
    required this.isVerified,
    this.session,
  });

  final HiringRequest hire;
  final JobSession? session;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RecruiterProvider>();
    final isAccepted = hire.status == 'accepted';
    final isSessionCreated = hire.status == 'session_created';
    final isStarted = hire.status == 'started';
    final isAwaitingPayment = hire.status == 'awaiting_payment';
    final isCompleted = hire.status == 'completed';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _Avatar(name: hire.workerName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hire.workerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.onBackground,
                      ),
                    ),
                    Text(
                      hire.profession,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.subtle,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: hire.status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 13, color: AppTheme.subtle),
              const SizedBox(width: 4),
              Text(
                hire.phone,
                style: const TextStyle(fontSize: 12, color: AppTheme.subtle),
              ),
            ],
          ),

          // ── STEP 5: Accepted → Start Work ──────────────────────────────
          if (isAccepted) ...[
            if (!isVerified)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Please verify your account to continue',
                  style: TextStyle(color: AppTheme.warning, fontSize: 12),
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                label: const Text('Start Work (Generate OTP)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
                onPressed: provider.isLoading || !isVerified
                    ? null
                    : () async {
                        final session =
                            await provider.startWork(hire: hire);
                        if (!context.mounted) return;
                        if (session != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  JobSessionScreen(session: session),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text(provider.error ?? 'Failed to start'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                        }
                      },
              ),
            ),
          ],

          // ── Session created → View OTP again ──────────────────────────
          if ((isSessionCreated || isStarted) && session != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (isSessionCreated) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.key_rounded, size: 14),
                      label: const Text('View OTP'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JobSessionScreen(session: session!),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Job started
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.map_rounded, size: 14),
                      label: const Text('Track Live'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobSessionScreen(session: session!),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],

          // ── Completed → Pay ────────────────────────────────────────────
          if ((isAwaitingPayment || isCompleted) && session != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.currency_rupee_rounded, size: 16),
                label: session!.paymentStatus == 'paid'
                    ? const Text('Payment Done ✓')
                    : const Text('Pay Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: session!.paymentStatus == 'paid'
                      ? AppTheme.subtle
                      : AppTheme.success,
                ),
                onPressed: session!.paymentStatus == 'paid' || provider.isLoading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobSessionScreen(session: session!),
                          ),
                        ),
              ),
            ),
            // Rate Worker after payment
            if (session!.paymentStatus == 'paid') ...[
              const SizedBox(height: 8),
              _RateWorkerButton(hire: hire, session: session!),
            ],
          ],

          // Message Worker (shown for accepted and beyond)
          if (isAccepted || isSessionCreated || isStarted || isAwaitingPayment || isCompleted) ...[
            const SizedBox(height: 8),
            _MessageWorkerButton(hire: hire),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ── Rate Worker Button ─────────────────────────────────────────────────────

class _RateWorkerButton extends StatefulWidget {
  const _RateWorkerButton({required this.hire, required this.session});
  final HiringRequest hire;
  final JobSession session;

  @override
  State<_RateWorkerButton> createState() => _RateWorkerButtonState();
}

class _RateWorkerButtonState extends State<_RateWorkerButton> {
  bool _rated = false;

  @override
  Widget build(BuildContext context) {
    if (_rated) {
      return const Center(
        child: Text(
          'Thanks for your rating! ⭐',
          style: TextStyle(color: AppTheme.warning, fontSize: 12),
        ),
      );
    }
    final currentUser = context.read<AuthProvider>().currentUser;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.star_outline_rounded, size: 16),
        label: const Text('Rate Worker'),
        onPressed: () async {
          if (currentUser == null) return;
          final ok = await showRateUserDialog(
            context: context,
            fromUserId: currentUser.uid,
            fromUserName: currentUser.name,
            toUserId: widget.hire.workerId,
            toUserName: widget.hire.workerName,
            jobId: widget.hire.jobId,
            isRatingWorker: true,
          );
          if (ok && mounted) setState(() => _rated = true);
        },
      ),
    );
  }
}

// ── Message Worker Button ──────────────────────────────────────────────────

class _MessageWorkerButton extends StatelessWidget {
  const _MessageWorkerButton({required this.hire});
  final HiringRequest hire;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
        label: const Text('Message Worker'),
        onPressed: () async {
          if (currentUser == null) return;
          final chatRepo = context.read<ChatRepository>();
          final chatId = chatRepo.getChatId(currentUser.uid, hire.workerId);
          await context.read<ChatProvider>().openOrCreateChat(
                myUid: currentUser.uid,
                myName: currentUser.name,
                otherUid: hire.workerId,
                otherName: hire.workerName,
              );
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: chatId,
                otherUserId: hire.workerId,
                otherUserName: hire.workerName,
                currentUserId: currentUser.uid,
                currentUserName: currentUser.name,
              ),
            ),
          );
        },
      ),
    );
  }
}

