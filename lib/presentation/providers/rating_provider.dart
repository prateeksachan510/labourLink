import 'package:flutter/material.dart';
import 'package:labour_link/data/models/rating.dart';
import 'package:labour_link/data/services/fraud_service.dart';
import 'package:labour_link/domain/repositories/rating_repository.dart';

class RatingProvider extends ChangeNotifier {
  RatingProvider(this._ratingRepository);

  final RatingRepository _ratingRepository;

  bool isLoading = false;
  String? error;

  // Cached ratings per userId key
  final Map<String, List<Rating>> _cache = {};
  final Map<String, double> _averages = {};
  final Map<String, int> _counts = {};

  List<Rating> ratingsFor(String userId) => _cache[userId] ?? [];
  double averageFor(String userId) => _averages[userId] ?? 0.0;
  int countFor(String userId) => _counts[userId] ?? 0;

  Future<void> loadRatings(String userId) async {
    debugPrint('[RatingProvider] loadRatings uid=$userId');
    try {
      final list = await _ratingRepository.getRatingsFor(userId);
      _cache[userId] = list;
      if (list.isNotEmpty) {
        final sum = list.fold<int>(0, (acc, r) => acc + r.rating);
        _averages[userId] = double.parse((sum / list.length).toStringAsFixed(1));
        _counts[userId] = list.length;
      }
      debugPrint(
        '[RatingProvider] loaded ${list.length} ratings avg=${_averages[userId]} uid=$userId',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[RatingProvider] loadRatings error: $e');
    }
  }

  Future<bool> submitRating({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String jobId,
    required int stars,
    String review = '',
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    debugPrint(
      '[RatingProvider] submitRating from=$fromUserId to=$toUserId '
      'jobId=$jobId stars=$stars',
    );
    try {
      // Prevent duplicate
      final already = await _ratingRepository.hasRated(
        jobId: jobId,
        fromUserId: fromUserId,
      );
      if (already) {
        debugPrint(
          '[RatingProvider] duplicate rating prevented jobId=$jobId from=$fromUserId',
        );
        await FraudService.logEvent(
          userId: fromUserId,
          action: 'duplicate_rating',
          reason: 'Attempted duplicate rating for jobId=$jobId',
        );
        error = 'You have already rated this job.';
        return false;
      }

      final ratingCooldown = await FraudService.isInCooldown(
        fromUserId,
        'submit_rating',
        cooldownMs: 5000,
      );
      if (ratingCooldown) {
        error = 'Please wait before submitting another rating.';
        await FraudService.logEvent(
          userId: fromUserId,
          action: 'rating_spam',
          reason: 'Rapid rating submission',
        );
        return false;
      }

      final rating = Rating.create(
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        toUserId: toUserId,
        jobId: jobId,
        rating: stars,
        review: review,
      );
      await _ratingRepository.submitRating(rating);
      await FraudService.stampAction(fromUserId, 'submit_rating');
      // Reload cache for the recipient
      await loadRatings(toUserId);
      debugPrint('[RatingProvider] rating submitted ratingId=${rating.ratingId}');
      return true;
    } catch (e) {
      debugPrint('[RatingProvider] submitRating error: $e');
      error = 'Failed to submit rating. Try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> hasRated({
    required String jobId,
    required String fromUserId,
  }) {
    return _ratingRepository.hasRated(jobId: jobId, fromUserId: fromUserId);
  }
}
