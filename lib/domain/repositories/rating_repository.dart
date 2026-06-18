import 'package:labour_link/data/models/rating.dart';

abstract class RatingRepository {
  Future<void> submitRating(Rating rating);
  Future<List<Rating>> getRatingsFor(String userId);
  Future<bool> hasRated({required String jobId, required String fromUserId});
  Future<double> getAverageRating(String userId);
  Stream<double> watchAverageRating(String userId);
}
