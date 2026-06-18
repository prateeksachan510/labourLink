import 'package:labour_link/data/models/hiring_request.dart';

abstract class HiringRepository {
  Future<void> sendRequest(HiringRequest request);
  Future<List<HiringRequest>> getRecruiterRequests(String recruiterId);
  Future<List<HiringRequest>> getWorkerRequests(String workerId);
  Future<void> updateRequestStatus({
    required String recruiterId,
    required String workerId,
    required String status,
  });

  /// Real-time stream of all requests for a seeker (filtered by workerId).
  Stream<List<HiringRequest>> watchWorkerRequests(String workerId);

  /// Real-time stream of all requests created by a recruiter.
  Stream<List<HiringRequest>> watchRecruiterRequests(String recruiterId);
}
