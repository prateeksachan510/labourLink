import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:labour_link/core/constants/firebase_paths.dart';
import 'package:labour_link/data/models/earnings_summary.dart';
import 'package:labour_link/data/services/firebase_service.dart';
import 'package:labour_link/domain/repositories/earnings_repository.dart';

class EarningsRepositoryImpl implements EarningsRepository {
  DatabaseReference get _sessionsRef =>
      FirebaseService.db.ref(FirebasePaths.jobSessions);

  DatabaseReference _earningsRef(String workerId) =>
      FirebaseService.db.ref('${FirebasePaths.earnings}/$workerId');

  DatabaseReference _userRef(String workerId) =>
      FirebaseService.db.ref('${FirebasePaths.users}/$workerId');

  @override
  Future<EarningsSummary> getEarningsSummary(String workerId) async {
    debugPrint('[EarningsRepo] getEarningsSummary workerId=$workerId');

    final averageRating = await _getAverageRating(workerId);
    final ratingCount = await _getRatingCount(workerId);

    // Always recompute from raw sessions for accuracy
    final summary = await _computeFromSessions(workerId);

    final result = summary.copyWith(
      averageRating: averageRating,
      ratingCount: ratingCount,
      lastUpdated: DateTime.now().toIso8601String(),
    );

    // Cache the result
    await _earningsRef(workerId).set({
      'totalEarnings': result.totalEarnings,
      'monthlyEarnings': result.monthlyEarnings,
      'weeklyEarnings': result.weeklyEarnings,
      'completedJobs': result.completedJobs,
      'pendingPayments': result.pendingPayments,
      'lastUpdated': result.lastUpdated,
    });

    debugPrint(
      '[EarningsRepo] computed: total=${result.totalEarnings} '
      'monthly=${result.monthlyEarnings} weekly=${result.weeklyEarnings} '
      'jobs=${result.completedJobs} rating=${result.averageRating}',
    );
    return result;
  }

  @override
  Future<void> refreshEarnings(String workerId) async {
    await getEarningsSummary(workerId);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<EarningsSummary> _computeFromSessions(String workerId) async {
    final snap = await _sessionsRef.get();
    if (!snap.exists || snap.value == null) {
      return const EarningsSummary();
    }

    final raw = (snap.value as Map).cast<Object?, Object?>();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfWeek =
        now.subtract(Duration(days: now.weekday - 1));
    final weekCutoff = DateTime(
        startOfWeek.year, startOfWeek.month, startOfWeek.day);

    int total = 0;
    int monthly = 0;
    int weekly = 0;
    int completedJobs = 0;
    int pendingPayments = 0;
    final recentPayments = <RecentPayment>[];

    for (final entry in raw.entries) {
      if (entry.value is! Map) continue;
      final s = (entry.value as Map).cast<Object?, Object?>();

      final wId = (s['workerId'] ?? '').toString();
      if (wId != workerId) continue;

      final payStatus = (s['paymentStatus'] ?? '').toString();
      final status = (s['status'] ?? '').toString();
      final isPaid = payStatus == 'paid' || payStatus == 'done';

      if (status == 'awaiting_payment' && !isPaid) {
        pendingPayments++;
        continue;
      }

      if (!isPaid) continue;

      final amount =
          int.tryParse((s['amount'] ?? '0').toString()) ?? 0;
      final completedAt = (s['completedAt'] ?? '').toString();

      total += amount;
      completedJobs++;

      // Monthly + weekly breakdown
      DateTime? completedDate;
      try {
        completedDate = DateTime.parse(completedAt);
      } catch (_) {}

      if (completedDate != null) {
        if (!completedDate.isBefore(startOfMonth)) {
          monthly += amount;
        }
        if (!completedDate.isBefore(weekCutoff)) {
          weekly += amount;
        }
      }

      // Recent payments (keep last 10)
      if (recentPayments.length < 10) {
        recentPayments.add(RecentPayment(
          jobId: (s['jobId'] ?? '').toString(),
          recruiterName: (s['recruiterName'] ?? '').toString(),
          amount: amount,
          paidAt: completedAt,
          profession: (s['profession'] ?? '').toString(),
        ));
      }
    }

    // Sort recent payments newest first
    recentPayments.sort((a, b) => b.paidAt.compareTo(a.paidAt));

    debugPrint(
      '[EarningsRepo] _computeFromSessions workerId=$workerId '
      'total=$total pending=$pendingPayments jobs=$completedJobs',
    );

    return EarningsSummary(
      totalEarnings: total,
      monthlyEarnings: monthly,
      weeklyEarnings: weekly,
      completedJobs: completedJobs,
      pendingPayments: pendingPayments,
      recentPayments: recentPayments,
    );
  }

  Future<double> _getAverageRating(String workerId) async {
    try {
      final snap = await _userRef(workerId).child('averageRating').get();
      if (!snap.exists || snap.value == null) return 0.0;
      return double.tryParse(snap.value.toString()) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<int> _getRatingCount(String workerId) async {
    try {
      final snap = await _userRef(workerId).child('ratingCount').get();
      if (!snap.exists || snap.value == null) return 0;
      return int.tryParse(snap.value.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
