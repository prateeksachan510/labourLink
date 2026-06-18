class EarningsSummary {
  const EarningsSummary({
    this.totalEarnings = 0,
    this.monthlyEarnings = 0,
    this.weeklyEarnings = 0,
    this.completedJobs = 0,
    this.pendingPayments = 0,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.lastUpdated = '',
    this.recentPayments = const [],
  });

  final int totalEarnings;
  final int monthlyEarnings;
  final int weeklyEarnings;
  final int completedJobs;
  final int pendingPayments;
  final double averageRating;
  final int ratingCount;
  final String lastUpdated;
  final List<RecentPayment> recentPayments;

  EarningsSummary copyWith({
    int? totalEarnings,
    int? monthlyEarnings,
    int? weeklyEarnings,
    int? completedJobs,
    int? pendingPayments,
    double? averageRating,
    int? ratingCount,
    String? lastUpdated,
    List<RecentPayment>? recentPayments,
  }) =>
      EarningsSummary(
        totalEarnings: totalEarnings ?? this.totalEarnings,
        monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
        weeklyEarnings: weeklyEarnings ?? this.weeklyEarnings,
        completedJobs: completedJobs ?? this.completedJobs,
        pendingPayments: pendingPayments ?? this.pendingPayments,
        averageRating: averageRating ?? this.averageRating,
        ratingCount: ratingCount ?? this.ratingCount,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        recentPayments: recentPayments ?? this.recentPayments,
      );
}

class RecentPayment {
  const RecentPayment({
    required this.jobId,
    required this.recruiterName,
    required this.amount,
    required this.paidAt,
    required this.profession,
  });

  final String jobId;
  final String recruiterName;
  final int amount;
  final String paidAt;
  final String profession;
}
