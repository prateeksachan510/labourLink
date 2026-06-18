import 'package:uuid/uuid.dart';

class Rating {
  const Rating({
    required this.ratingId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.jobId,
    required this.rating,
    required this.createdAt,
    this.review = '',
  });

  final String ratingId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String jobId;

  /// Star rating 1–5.
  final int rating;
  final String review;
  final String createdAt;

  factory Rating.create({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String jobId,
    required int rating,
    String review = '',
  }) {
    return Rating(
      ratingId: const Uuid().v4(),
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      jobId: jobId,
      rating: rating.clamp(1, 5),
      review: review,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  factory Rating.fromMap(Map<Object?, Object?> map) {
    return Rating(
      ratingId: (map['ratingId'] ?? '').toString(),
      fromUserId: (map['fromUserId'] ?? '').toString(),
      fromUserName: (map['fromUserName'] ?? '').toString(),
      toUserId: (map['toUserId'] ?? '').toString(),
      jobId: (map['jobId'] ?? '').toString(),
      rating: int.tryParse((map['rating'] ?? '0').toString()) ?? 0,
      review: (map['review'] ?? '').toString(),
      createdAt: (map['createdAt'] ?? '').toString(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'ratingId': ratingId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'jobId': jobId,
      'rating': rating,
      'review': review,
      'createdAt': createdAt,
    };
  }
}
