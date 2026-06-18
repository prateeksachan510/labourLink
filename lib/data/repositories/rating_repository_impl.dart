import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:labour_link/core/constants/firebase_paths.dart';
import 'package:labour_link/data/models/rating.dart';
import 'package:labour_link/data/services/firebase_service.dart';
import 'package:labour_link/domain/repositories/rating_repository.dart';

class RatingRepositoryImpl implements RatingRepository {
  DatabaseReference get _ratingsRef =>
      FirebaseService.db.ref(FirebasePaths.ratings);
  DatabaseReference get _usersRef =>
      FirebaseService.db.ref(FirebasePaths.users);

  @override
  Future<void> submitRating(Rating rating) async {
    debugPrint(
      '[RatingRepo] submitRating ratingId=${rating.ratingId} '
      'from=${rating.fromUserId} to=${rating.toUserId} '
      'jobId=${rating.jobId} stars=${rating.rating}',
    );
    // Write the rating under the recipient's node.
    await _ratingsRef
        .child(rating.toUserId)
        .child(rating.ratingId)
        .set(rating.toMap());

    // Recompute and cache the average on the user node.
    await _updateCachedAverage(rating.toUserId);
    debugPrint('[RatingRepo] average updated for uid=${rating.toUserId}');
  }

  @override
  Future<List<Rating>> getRatingsFor(String userId) async {
    debugPrint('[RatingRepo] getRatingsFor uid=$userId');
    final snapshot = await _ratingsRef.child(userId).get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final map = (snapshot.value as Map).cast<Object?, Object?>();
    final list = map.values
        .map((e) => Rating.fromMap((e as Map).cast<Object?, Object?>()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    debugPrint('[RatingRepo] getRatingsFor: ${list.length} ratings for uid=$userId');
    return list;
  }

  @override
  Future<bool> hasRated({
    required String jobId,
    required String fromUserId,
  }) async {
    // Search across ALL toUserId nodes for a rating with this jobId+fromUserId.
    final snapshot = await _ratingsRef.get();
    if (!snapshot.exists || snapshot.value == null) return false;
    final allUsers = (snapshot.value as Map).cast<Object?, Object?>();
    for (final userRatings in allUsers.values) {
      if (userRatings is! Map) continue;
      for (final r in userRatings.cast<Object?, Object?>().values) {
        if (r is! Map) continue;
        final rating = Rating.fromMap(r.cast<Object?, Object?>());
        if (rating.jobId == jobId && rating.fromUserId == fromUserId) {
          debugPrint('[RatingRepo] hasRated=true jobId=$jobId from=$fromUserId');
          return true;
        }
      }
    }
    debugPrint('[RatingRepo] hasRated=false jobId=$jobId from=$fromUserId');
    return false;
  }

  @override
  Future<double> getAverageRating(String userId) async {
    final ratings = await getRatingsFor(userId);
    if (ratings.isEmpty) return 0.0;
    final sum = ratings.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / ratings.length;
  }

  @override
  Stream<double> watchAverageRating(String userId) {
    return _usersRef.child(userId).child('averageRating').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return 0.0;
      return double.tryParse(event.snapshot.value.toString()) ?? 0.0;
    });
  }

  Future<void> _updateCachedAverage(String userId) async {
    try {
      final ratings = await getRatingsFor(userId);
      if (ratings.isEmpty) return;
      final avg = ratings.fold<int>(0, (acc, r) => acc + r.rating) /
          ratings.length;
      final rounded = double.parse(avg.toStringAsFixed(1));
      await _usersRef.child(userId).update({
        'averageRating': rounded,
        'ratingCount': ratings.length,
      });
      debugPrint(
        '[RatingRepo] cached average updated uid=$userId avg=$rounded count=${ratings.length}',
      );
    } catch (e) {
      debugPrint('[RatingRepo] _updateCachedAverage error: $e');
    }
  }
}
