import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:labour_link/core/constants/firebase_paths.dart';
import 'package:labour_link/data/models/job_session.dart';
import 'package:labour_link/data/services/firebase_service.dart';
import 'package:labour_link/domain/repositories/job_session_repository.dart';

class JobSessionRepositoryImpl implements JobSessionRepository {
  // Helper to get the sessions root reference.
  DatabaseReference get _ref => FirebaseService.db.ref(FirebasePaths.jobSessions);

  // ── One-shot writes / reads ──────────────────────────────────────────────

  @override
  Future<void> createSession(JobSession session) async {
    debugPrint('[SessionRepo] createSession jobId=${session.jobId} '
        'recruiterId=${session.recruiterId} workerId=${session.workerId} '
        'otp=${session.otp}');
    await _ref.child(session.jobId).set(session.toMap());
  }

  @override
  Future<JobSession?> getSession(String jobId) async {
    debugPrint('[SessionRepo] getSession jobId=$jobId');
    final snapshot = await _ref.child(jobId).get();
    if (!snapshot.exists || snapshot.value == null) {
      debugPrint('[SessionRepo] getSession: not found for jobId=$jobId');
      return null;
    }
    final s = JobSession.fromMap(
        (snapshot.value as Map).cast<Object?, Object?>());
    debugPrint('[SessionRepo] getSession found: status=${s.status}');
    return s;
  }

  @override
  Future<void> updateStatus(String jobId, String status) async {
    debugPrint('[SessionRepo] updateStatus jobId=$jobId status=$status');
    await _ref.child(jobId).update({'status': status});
  }

  @override
  Future<void> updateAmount(String jobId, int amount) async {
    debugPrint('[SessionRepo] updateAmount jobId=$jobId amount=$amount');
    await _ref.child(jobId).update({'amount': amount});
  }

  @override
  Future<void> markPaymentCompleted({
    required String jobId,
    required int amount,
    String paymentMethod = 'upi',
  }) async {
    final completedAt = DateTime.now().toIso8601String();
    debugPrint(
      '[SessionRepo] markPaymentCompleted jobId=$jobId amount=$amount '
      'method=$paymentMethod completedAt=$completedAt',
    );
    await _ref.child(jobId).update({
      'amount': amount,
      'paymentStatus': 'paid',
      'paymentMethod': paymentMethod,
      'status': 'completed',
      'completedAt': completedAt,
    });
  }

  @override
  Future<List<JobSession>> getSessionsForWorker(String workerId) async {
    debugPrint('[SessionRepo] getSessionsForWorker workerId=$workerId');
    final snapshot = await _ref.get();
    return _filterAndSort(snapshot.value, (s) => s.workerId == workerId);
  }

  @override
  Future<List<JobSession>> getSessionsForRecruiter(
      String recruiterId) async {
    debugPrint('[SessionRepo] getSessionsForRecruiter recruiterId=$recruiterId');
    final snapshot = await _ref.get();
    return _filterAndSort(
        snapshot.value, (s) => s.recruiterId == recruiterId);
  }

  // ── Real-time streams ────────────────────────────────────────────────────

  @override
  Stream<JobSession?> watchSession(String jobId) {
    debugPrint('[SessionRepo] watchSession jobId=$jobId');
    return _ref.child(jobId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return null;
      final s = JobSession.fromMap(
          (event.snapshot.value as Map).cast<Object?, Object?>());
      debugPrint('[SessionRepo] watchSession update: status=${s.status}');
      return s;
    });
  }

  @override
  Stream<List<JobSession>> watchSessionsForWorker(String workerId) {
    debugPrint('[SessionRepo] watchSessionsForWorker workerId=$workerId');
    return _ref.onValue.map((event) {
      final result = _filterAndSort(
          event.snapshot.value, (s) => s.workerId == workerId);
      debugPrint('[SessionRepo] watchSessionsForWorker emitting '
          '${result.length} for workerId=$workerId');
      return result;
    });
  }

  @override
  Stream<List<JobSession>> watchSessionsForRecruiter(String recruiterId) {
    debugPrint('[SessionRepo] watchSessionsForRecruiter recruiterId=$recruiterId');
    return _ref.onValue.map((event) {
      final result = _filterAndSort(
          event.snapshot.value, (s) => s.recruiterId == recruiterId);
      debugPrint('[SessionRepo] watchSessionsForRecruiter emitting '
          '${result.length} for recruiterId=$recruiterId');
      return result;
    });
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  List<JobSession> _filterAndSort(
      Object? value, bool Function(JobSession) test) {
    if (value == null) return [];
    final map = (value as Map).cast<Object?, Object?>();
    return map.values
        .map((e) => JobSession.fromMap((e as Map).cast<Object?, Object?>()))
        .where(test)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
