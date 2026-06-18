import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:labour_link/core/constants/firebase_paths.dart';
import 'package:labour_link/data/models/hiring_request.dart';
import 'package:labour_link/data/services/firebase_service.dart';
import 'package:labour_link/domain/repositories/hiring_repository.dart';

class HiringRepositoryImpl implements HiringRepository {
  DatabaseReference get _ref =>
      FirebaseService.db.ref(FirebasePaths.hiringRequests);

  // ── One-shot writes / reads ──────────────────────────────────────────────

  @override
  Future<void> sendRequest(HiringRequest request) async {
    debugPrint('[HiringRepo] sendRequest recruiterId=${request.recruiterId} '
        'workerId=${request.workerId}');
    await _ref
        .child(request.recruiterId)
        .child(request.workerId)
        .set(request.toMap());
  }

  @override
  Future<List<HiringRequest>> getRecruiterRequests(
      String recruiterId) async {
    debugPrint('[HiringRepo] getRecruiterRequests recruiterId=$recruiterId');
    final snapshot = await _ref.child(recruiterId).get();
    return _parseRecruiterSnapshot(snapshot);
  }

  @override
  Future<List<HiringRequest>> getWorkerRequests(String workerId) async {
    debugPrint('[HiringRepo] getWorkerRequests workerId=$workerId');
    final snapshot = await _ref.get();
    if (!snapshot.exists || snapshot.value == null) return [];
    return _extractWorkerRequests(snapshot.value as Map, workerId);
  }

  @override
  Future<void> updateRequestStatus({
    required String recruiterId,
    required String workerId,
    required String status,
  }) async {
    debugPrint('[HiringRepo] updateStatus recruiterId=$recruiterId '
        'workerId=$workerId status=$status');
    await _ref.child(recruiterId).child(workerId).update({'status': status});
  }

  // ── Real-time streams ────────────────────────────────────────────────────

  @override
  Stream<List<HiringRequest>> watchWorkerRequests(String workerId) {
    debugPrint('[HiringRepo] watchWorkerRequests workerId=$workerId');
    return _ref.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final raw = event.snapshot.value as Map;
      final result = _extractWorkerRequests(raw, workerId);
      debugPrint('[HiringRepo] watchWorkerRequests emitting '
          '${result.length} requests for workerId=$workerId');
      return result;
    });
  }

  @override
  Stream<List<HiringRequest>> watchRecruiterRequests(String recruiterId) {
    debugPrint('[HiringRepo] watchRecruiterRequests recruiterId=$recruiterId');
    return _ref.child(recruiterId).onValue.map((event) {
      final result = _parseRecruiterSnapshot(event.snapshot);
      debugPrint('[HiringRepo] watchRecruiterRequests emitting '
          '${result.length} for recruiterId=$recruiterId');
      return result;
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<HiringRequest> _parseRecruiterSnapshot(DataSnapshot snapshot) {
    if (!snapshot.exists || snapshot.value == null) return [];
    final map = (snapshot.value as Map).cast<Object?, Object?>();
    return map.values
        .map((e) =>
            HiringRequest.fromMap((e as Map).cast<Object?, Object?>()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<HiringRequest> _extractWorkerRequests(Map raw, String workerId) {
    final recruiters = raw.cast<Object?, Object?>();
    final result = <HiringRequest>[];
    for (final entry in recruiters.entries) {
      if (entry.value is! Map) continue;
      final workerMap = (entry.value as Map).cast<Object?, Object?>();
      if (workerMap.containsKey(workerId)) {
        if (workerMap[workerId] is! Map) continue;
        final req = HiringRequest.fromMap(
            (workerMap[workerId] as Map).cast<Object?, Object?>());
        if (req.workerId == workerId) {
          result.add(req);
        }
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }
}
