import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/app_card.dart';
import 'package:labour_link/core/widgets/empty_state_view.dart';
import 'package:labour_link/core/widgets/loading_view.dart';
import 'package:labour_link/core/widgets/status_badge.dart';
import 'package:labour_link/data/models/hiring_request.dart';
import 'package:labour_link/data/models/job_session.dart';
import 'package:labour_link/domain/repositories/chat_repository.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/chat_provider.dart';
import 'package:labour_link/presentation/providers/seeker_provider.dart';
import 'package:labour_link/presentation/screens/common/chat_screen.dart';
import 'package:labour_link/presentation/screens/common/rate_user_dialog.dart';
import 'package:labour_link/presentation/screens/common/verification_center_screen.dart';
import 'package:labour_link/presentation/screens/seeker/otp_confirm_screen.dart';
import 'package:provider/provider.dart';

/// STEP 2 & 3 — Seeker views incoming requests and accepts/rejects them.
class SeekerRequestsScreen extends StatelessWidget {
  const SeekerRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final seeker = context.watch<SeekerProvider>();
    final currentUser = context.watch<AuthProvider>().currentUser;
    final uid = currentUser?.uid;
    final isVerified = currentUser?.isVerified ?? false;

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
                          'Hire Requests',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onBackground,
                          ),
                        ),
                        Text(
                          '${seeker.requests.length} total',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.subtle,
                          ),
                        ),
                      ],
                    ),
                    // Live indicator
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
                    : seeker.isLoading && seeker.requests.isEmpty
                        ? const LoadingView()
                        : seeker.requests.isEmpty
                            ? const EmptyStateView(
                                message: 'No hiring requests yet.\n'
                                    'Your requests will appear here in real-time.')
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: seeker.requests.length,
                                itemBuilder: (context, index) {
                                  final req = seeker.requests[index];
                                  final session = seeker.sessions
                                      .where((s) => s.jobId == req.jobId)
                                      .firstOrNull;
                                  return _RequestCard(
                                    request: req,
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.isVerified,
    this.session,
  });

  final HiringRequest request;
  final JobSession? session;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final seeker = context.read<SeekerProvider>();
    final isPending = request.status == 'pending';
    final isAccepted = request.status == 'accepted';
    final isSessionCreated = request.status == 'session_created';
    final isStarted = request.status == 'started';
    final isAwaitingPayment = request.status == 'awaiting_payment';
    final isCompleted = request.status == 'completed';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _Avatar(name: request.recruiterName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.recruiterName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.onBackground,
                      ),
                    ),
                    Text(
                      request.profession,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.subtle,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: request.status),
            ],
          ),

          // Address row
          if (request.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppTheme.subtle),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.address,
                    style: const TextStyle(fontSize: 12, color: AppTheme.subtle),
                  ),
                ),
              ],
            ),
          ],

          // ── STEP 3: Accept / Reject ────────────────────────────────────
          if (isPending) ...[
            if (!isVerified)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerificationCenterScreen(),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withAlpha(18),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppTheme.warning.withAlpha(70)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 14, color: AppTheme.warning),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verify your account to accept or reject jobs.',
                          style: TextStyle(
                              color: AppTheme.warning, fontSize: 12),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Verify →',
                        style: TextStyle(
                          color: AppTheme.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: !isVerified
                        ? null
                        : () => seeker.updateRequest(
                      request: request,
                      status: 'rejected',
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: !isVerified
                        ? null
                        : () => seeker.updateRequest(
                      request: request,
                      status: 'accepted',
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],

          // ── Accepted: waiting for recruiter to start ───────────────────
          if (isAccepted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top_rounded,
                      size: 14, color: AppTheme.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Accepted! Waiting for recruiter to start work.',
                      style: TextStyle(fontSize: 12, color: AppTheme.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── STEP 6: Recruiter started → OTP entry ─────────────────────
          if (isSessionCreated && session != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.key_rounded, size: 16),
                label: const Text('Enter OTP to Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
                onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OtpConfirmScreen(session: session!),
                      ),
                    ),
              ),
            ),
          ],

          // ── Job in Progress ────────────────────────────────────────────
          if (isStarted && session != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.work_rounded, size: 14, color: AppTheme.success),
                  SizedBox(width: 8),
                  Text(
                    'Job in Progress',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.task_alt_rounded, size: 16),
                label: const Text('Mark as Completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                ),
                onPressed: () => seeker.completeJob(
                      jobId: session!.jobId,
                      workerId: session!.workerId,
                      recruiterId: session!.recruiterId,
                    ),
              ),
            ),
          ],

          // ── Completed / Paid ────────────────────────────────────────────
          if (isAwaitingPayment) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.warning.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_bottom_rounded,
                      size: 14, color: AppTheme.warning),
                  SizedBox(width: 8),
                  Text(
                    'Awaiting Recruiter Payment',
                    style: TextStyle(fontSize: 12, color: AppTheme.warning),
                  ),
                ],
              ),
            ),
          ],

          if (isCompleted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.success.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success.withAlpha(60)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.payments_rounded,
                      size: 14, color: AppTheme.success),
                  SizedBox(width: 8),
                  Text(
                    'Payment Received ✅',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Rate Recruiter button (shown after payment complete)
            _RateRecruiterButton(request: request),
          ],

          // ── Message Recruiter (shown when accepted or later) ──────────────
          if (isAccepted || isSessionCreated || isStarted || isAwaitingPayment || isCompleted) ...[
            const SizedBox(height: 10),
            _MessageRecruiterButton(request: request),
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

// ── Rate Recruiter Button ──────────────────────────────────────────────────

class _RateRecruiterButton extends StatefulWidget {
  const _RateRecruiterButton({required this.request});
  final HiringRequest request;

  @override
  State<_RateRecruiterButton> createState() => _RateRecruiterButtonState();
}

class _RateRecruiterButtonState extends State<_RateRecruiterButton> {
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
        label: const Text('Rate Recruiter'),
        onPressed: () async {
          if (currentUser == null) return;
          final ok = await showRateUserDialog(
            context: context,
            fromUserId: currentUser.uid,
            fromUserName: currentUser.name,
            toUserId: widget.request.recruiterId,
            toUserName: widget.request.recruiterName,
            jobId: widget.request.jobId,
            isRatingWorker: false,
          );
          if (ok && mounted) setState(() => _rated = true);
        },
      ),
    );
  }
}

// ── Message Recruiter Button ───────────────────────────────────────────────

class _MessageRecruiterButton extends StatelessWidget {
  const _MessageRecruiterButton({required this.request});
  final HiringRequest request;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
        label: const Text('Message Recruiter'),
        onPressed: () async {
          if (currentUser == null) return;
          final chatRepo = context.read<ChatRepository>();
          final chatId = chatRepo.getChatId(
            currentUser.uid,
            request.recruiterId,
          );
          await context.read<ChatProvider>().openOrCreateChat(
                myUid: currentUser.uid,
                myName: currentUser.name,
                otherUid: request.recruiterId,
                otherName: request.recruiterName,
              );
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: chatId,
                otherUserId: request.recruiterId,
                otherUserName: request.recruiterName,
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

