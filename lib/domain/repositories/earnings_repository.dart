import 'package:labour_link/data/models/earnings_summary.dart';

abstract class EarningsRepository {
  Future<EarningsSummary> getEarningsSummary(String workerId);
  Future<void> refreshEarnings(String workerId);
}
