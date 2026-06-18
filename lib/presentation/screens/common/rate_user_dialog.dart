import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/star_rating_bar.dart';
import 'package:labour_link/presentation/providers/rating_provider.dart';
import 'package:provider/provider.dart';

/// Shows a bottom-sheet dialog for rating a user after job completion.
/// Returns true if rating was successfully submitted.
Future<bool> showRateUserDialog({
  required BuildContext context,
  required String fromUserId,
  required String fromUserName,
  required String toUserId,
  required String toUserName,
  required String jobId,
  required bool isRatingWorker, // true = recruiter rating worker, false = worker rating recruiter
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RateUserSheet(
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      jobId: jobId,
      isRatingWorker: isRatingWorker,
    ),
  );
  return result ?? false;
}

class _RateUserSheet extends StatefulWidget {
  const _RateUserSheet({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.jobId,
    required this.isRatingWorker,
  });

  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final String jobId;
  final bool isRatingWorker;

  @override
  State<_RateUserSheet> createState() => _RateUserSheetState();
}

class _RateUserSheetState extends State<_RateUserSheet> {
  int _stars = 0;
  final _reviewCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a star rating first.'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
    final ratingProvider = context.read<RatingProvider>();
    final ok = await ratingProvider.submitRating(
      fromUserId: widget.fromUserId,
      fromUserName: widget.fromUserName,
      toUserId: widget.toUserId,
      jobId: widget.jobId,
      stars: _stars,
      review: _reviewCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _submitted = true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ratingProvider.error ?? 'Could not submit rating.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingProvider = context.watch<RatingProvider>();
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _submitted
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppTheme.success, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Rating submitted!',
                      style: TextStyle(
                        color: AppTheme.onBackground,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.subtle.withAlpha(80),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      widget.isRatingWorker
                          ? 'Rate ${widget.toUserName}'
                          : 'Rate ${widget.toUserName}',
                      style: const TextStyle(
                        color: AppTheme.onBackground,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      widget.isRatingWorker
                          ? 'How was your experience with this worker?'
                          : 'How was your experience with this recruiter?',
                      style: const TextStyle(
                        color: AppTheme.subtle,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stars
                    Center(
                      child: StarRatingBar(
                        rating: _stars.toDouble(),
                        interactive: true,
                        starSize: 40,
                        onRatingChanged: (v) => setState(() => _stars = v),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _stars == 0
                            ? 'Tap a star'
                            : _starLabel(_stars),
                        style: TextStyle(
                          color: _stars == 0
                              ? AppTheme.subtle
                              : AppTheme.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Review field
                    TextField(
                      controller: _reviewCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Add a review (optional)…',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: ratingProvider.isLoading ? null : _submit,
                        child: ratingProvider.isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submit Rating'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Skip'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _starLabel(int stars) {
    return switch (stars) {
      1 => 'Poor',
      2 => 'Fair',
      3 => 'Good',
      4 => 'Very Good',
      5 => 'Excellent!',
      _ => '',
    };
  }
}
