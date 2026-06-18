import 'package:flutter/material.dart';
import 'package:labour_link/data/models/earnings_summary.dart';
import 'package:labour_link/domain/repositories/earnings_repository.dart';

class EarningsProvider extends ChangeNotifier {
  EarningsProvider(this._repo);
  final EarningsRepository _repo;

  EarningsSummary _summary = const EarningsSummary();
  bool _isLoading = false;
  String? _error;

  EarningsSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadEarnings(String workerId) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      debugPrint('[EarningsProvider] loadEarnings workerId=$workerId');
      _summary = await _repo.getEarningsSummary(workerId);
      debugPrint(
        '[EarningsProvider] loaded: total=${_summary.totalEarnings} '
        'jobs=${_summary.completedJobs}',
      );
    } catch (e) {
      debugPrint('[EarningsProvider] error: $e');
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh(String workerId) async {
    debugPrint('[EarningsProvider] refresh workerId=$workerId');
    await loadEarnings(workerId);
  }
}
