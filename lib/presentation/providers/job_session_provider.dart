import 'package:flutter/material.dart';
import 'package:labour_link/data/models/job_session.dart';
import 'package:labour_link/data/services/payment_service.dart';
import 'package:labour_link/domain/repositories/job_session_repository.dart';

class JobSessionProvider extends ChangeNotifier {
  JobSessionProvider(this._repo);

  final JobSessionRepository _repo;

  bool isLoading = false;
  String? error;
  List<JobSession> workerSessions = [];
  List<JobSession> recruiterSessions = [];
  JobSession? activeSession;

  Future<JobSession?> createSession({
    required String recruiterId,
    required String workerId,
    required String recruiterName,
    required String workerName,
    required String profession,
    required String address,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final otp = PaymentService.generateOtp();
      final jobId = '${recruiterId}_${workerId}_${DateTime.now().millisecondsSinceEpoch}';
      final session = JobSession(
        jobId: jobId,
        recruiterId: recruiterId,
        workerId: workerId,
        recruiterName: recruiterName,
        workerName: workerName,
        profession: profession,
        otp: otp,
        status: 'pending',
        address: address,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _repo.createSession(session);
      return session;
    } catch (e) {
      error = 'Failed to create job session';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> validateAndStartSession({
    required String jobId,
    required String enteredOtp,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final session = await _repo.getSession(jobId);
      if (session == null) {
        error = 'Session not found';
        return false;
      }
      if (session.otp != enteredOtp) {
        error = 'Incorrect OTP. Please try again.';
        return false;
      }
      await _repo.updateStatus(jobId, 'started');
      activeSession = session.copyWith(status: 'started');
      return true;
    } catch (e) {
      error = 'Failed to validate OTP';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeSession(String jobId) async {
    await _repo.updateStatus(jobId, 'completed');
    await loadWorkerSessions(activeSession?.workerId ?? '');
  }

  Future<bool> payForSession({
    required String jobId,
    required String workerName,
    required int amount,
    String upiId = 'worker@upi',
  }) async {
    final launched = await PaymentService.payViaUpi(
      upiId: upiId,
      name: workerName,
      amount: amount,
      note: 'LabourLink Job Payment',
    );
    return launched == UpiLaunchResult.launched;
  }

  Future<void> loadWorkerSessions(String workerId) async {
    if (workerId.isEmpty) return;
    isLoading = true;
    notifyListeners();
    workerSessions = await _repo.getSessionsForWorker(workerId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecruiterSessions(String recruiterId) async {
    if (recruiterId.isEmpty) return;
    isLoading = true;
    notifyListeners();
    recruiterSessions = await _repo.getSessionsForRecruiter(recruiterId);
    isLoading = false;
    notifyListeners();
  }

  Future<JobSession?> getSession(String jobId) async {
    return _repo.getSession(jobId);
  }
}
