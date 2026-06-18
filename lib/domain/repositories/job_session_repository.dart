import 'package:labour_link/data/models/job_session.dart';

abstract class JobSessionRepository {
  Future<void> createSession(JobSession session);
  Future<JobSession?> getSession(String jobId);
  Future<void> updateStatus(String jobId, String status);
  Future<void> updateAmount(String jobId, int amount);
  Future<void> markPaymentCompleted({
    required String jobId,
    required int amount,
    String paymentMethod = 'upi',
  });
  Future<List<JobSession>> getSessionsForWorker(String workerId);
  Future<List<JobSession>> getSessionsForRecruiter(String recruiterId);

  /// Real-time stream of a single job session.
  Stream<JobSession?> watchSession(String jobId);

  /// Real-time stream of all sessions for a seeker.
  Stream<List<JobSession>> watchSessionsForWorker(String workerId);

  /// Real-time stream of all sessions created by a recruiter.
  Stream<List<JobSession>> watchSessionsForRecruiter(String recruiterId);
}
