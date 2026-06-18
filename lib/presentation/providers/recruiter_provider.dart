import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:labour_link/data/models/app_user.dart';
import 'package:labour_link/data/models/hiring_request.dart';
import 'package:labour_link/data/models/job_session.dart';
import 'package:labour_link/data/services/fraud_service.dart';
import 'package:labour_link/data/services/payment_service.dart';
import 'package:labour_link/data/services/notification_service.dart';
import 'package:labour_link/domain/repositories/hiring_repository.dart';
import 'package:labour_link/domain/repositories/job_session_repository.dart';
import 'package:labour_link/domain/repositories/user_repository.dart';

class RecruiterProvider extends ChangeNotifier {
  RecruiterProvider(
    this._userRepository,
    this._hiringRepository,
    this._jobSessionRepository,
  );

  final UserRepository _userRepository;
  final HiringRepository _hiringRepository;
  final JobSessionRepository _jobSessionRepository;

  bool isLoading = false;
  String? error;
  List<AppUser> workers = [];
  List<HiringRequest> myHires = [];
  List<JobSession> mySessions = [];

  String? _watchedRecruiterId;
  StreamSubscription<List<HiringRequest>>? _hiresSub;
  StreamSubscription<List<JobSession>>? _sessionsSub;

  // ── Static data ──────────────────────────────────────────────────────────

  static const professions = <String>[
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'Mason',
    'Driver',
    'Welder',
    'Cleaner',
    'Tailor',
    'Cook',
  ];

  static const Map<String, IconData> professionIcons = {
    'Electrician': Icons.electrical_services,
    'Plumber': Icons.plumbing,
    'Carpenter': Icons.handyman,
    'Painter': Icons.format_paint,
    'Mason': Icons.construction,
    'Driver': Icons.directions_car,
    'Welder': Icons.build,
    'Cleaner': Icons.cleaning_services,
    'Tailor': Icons.content_cut,
    'Cook': Icons.restaurant,
  };

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Call once when the recruiter shell mounts.
  void startWatching(String recruiterId) {
    if (_watchedRecruiterId == recruiterId) {
      debugPrint('[RecruiterProvider] Already watching recruiterId=$recruiterId');
      return;
    }
    debugPrint('[RecruiterProvider] startWatching recruiterId=$recruiterId');
    _watchedRecruiterId = recruiterId;
    _cancelSubs();

    _hiresSub = _hiringRepository.watchRecruiterRequests(recruiterId).listen(
      (data) {
        debugPrint('[RecruiterProvider] Hires updated: ${data.length} items');
        myHires = data;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[RecruiterProvider] Hires stream error: $e');
        error = 'Failed to load hires';
        notifyListeners();
      },
    );

    _sessionsSub = _jobSessionRepository
        .watchSessionsForRecruiter(recruiterId)
        .listen(
      (data) {
        debugPrint('[RecruiterProvider] Sessions updated: ${data.length} items');
        mySessions = data;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[RecruiterProvider] Sessions stream error: $e');
      },
    );
  }

  void stopWatching() {
    debugPrint('[RecruiterProvider] stopWatching');
    _watchedRecruiterId = null;
    _cancelSubs();
  }

  void _cancelSubs() {
    _hiresSub?.cancel();
    _sessionsSub?.cancel();
    _hiresSub = null;
    _sessionsSub = null;
  }

  @override
  void dispose() {
    _cancelSubs();
    super.dispose();
  }

  // ── Worker search ────────────────────────────────────────────────────────

  Future<void> loadWorkers(String profession, {String query = ''}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      workers = await _userRepository.searchSeekers(
        profession: profession,
        query: query,
      );
      debugPrint('[RecruiterProvider] loadWorkers found ${workers.length} '
          'for profession=$profession query=$query');
    } catch (e) {
      debugPrint('[RecruiterProvider] loadWorkers error: $e');
      error = 'Failed to load workers';
      workers = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── STEP 1: Hire ─────────────────────────────────────────────────────────
  /// Creates a HiringRequest with status=pending.
  /// Does NOT create a JobSession yet — that happens in [startWork].
  Future<bool> hireWorker({
    required String recruiterId,
    required String recruiterName,
    required AppUser worker,
    required String address,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    debugPrint(
      '[RecruiterProvider] hireWorker uid=$recruiterId '
      'workerId=${worker.uid} recruiterId=$recruiterId',
    );
    try {
      // ── Fraud: check if recruiter is blocked ─────────────────────────────
      final blocked = await FraudService.isUserBlocked(recruiterId);
      if (blocked) {
        error = 'Your account has been restricted. Contact support.';
        return false;
      }

      // ── Fraud: block duplicate pending hire to same worker ───────────────
      final existingPending = myHires.any(
        (h) =>
            h.workerId == worker.uid &&
            (h.status == 'pending' || h.status == 'accepted'),
      );
      if (existingPending) {
        error = 'You already have an active request with this worker.';
        await FraudService.logEvent(
          userId: recruiterId,
          action: 'duplicate_hire',
          reason: 'Duplicate hire attempt for worker=${worker.uid}',
        );
        return false;
      }

      // ── Fraud: 60-second cooldown between requests to the same worker ────
      final cooldownKey = 'hire_${worker.uid}';
      final inCooldown = await FraudService.isInCooldown(
        recruiterId,
        cooldownKey,
        cooldownMs: 60000,
      );
      if (inCooldown) {
        error = 'Please wait before sending another request to this worker.';
        await FraudService.logEvent(
          userId: recruiterId,
          action: 'hire_cooldown_blocked',
          reason: 'Attempted hire within cooldown for worker=${worker.uid}',
        );
        return false;
      }

      final isVerified = await _isUserVerified(recruiterId);
      if (!isVerified) {
        error = 'Please verify your account to continue';
        return false;
      }
      // Generate a stable jobId so we can link the session later.
      final jobId = _makeJobId(recruiterId, worker.uid);
      final nowIso = DateTime.now().toIso8601String();
      final request = HiringRequest(
        recruiterId: recruiterId,
        workerId: worker.uid,
        recruiterName: recruiterName,
        workerName: worker.name,
        profession: worker.profession,
        phone: worker.phone,
        status: 'pending',
        createdAt: nowIso,
        jobId: jobId,
        address: address,
      );
      await _hiringRepository.sendRequest(request);
      debugPrint('[RecruiterProvider] HiringRequest saved with jobId=$jobId');

      // Stamp cooldown timestamp
      await FraudService.stampAction(recruiterId, 'hire_${worker.uid}');

      // Notify the seeker about the new hire request
      unawaited(NotificationService.sendToUser(
        toUserId: worker.uid,
        title: 'New Hire Request 💼',
        body: '$recruiterName wants to hire you as ${worker.profession}.',
        data: {'type': 'hire_request', 'jobId': jobId},
      ));
      return true;
    } catch (e) {
      debugPrint('[RecruiterProvider] hireWorker error: $e');
      error = 'Failed to send hire request';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── STEP 5: Start work ───────────────────────────────────────────────────
  /// Called when recruiter clicks "Start Work" on an accepted hire.
  /// Creates the JobSession with a fresh OTP.
  Future<JobSession?> startWork({required HiringRequest hire}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    debugPrint('[RecruiterProvider] startWork jobId=${hire.jobId}');
    try {
      final isVerified = await _isUserVerified(hire.recruiterId);
      if (!isVerified) {
        error = 'Please verify your account to continue';
        return null;
      }
      final otp = _generateOtp();
      final nowIso = DateTime.now().toIso8601String();
      debugPrint('[RecruiterProvider] Generated OTP=$otp for jobId=${hire.jobId}');

      final session = JobSession(
        jobId: hire.jobId,
        recruiterId: hire.recruiterId,
        workerId: hire.workerId,
        recruiterName: hire.recruiterName,
        workerName: hire.workerName,
        profession: hire.profession,
        otp: otp,
        status: 'pending',
        address: hire.address,
        createdAt: nowIso,
        otpCreatedAt: nowIso,
      );
      await _jobSessionRepository.createSession(session);

      // Update hiring request status to "started" (session created).
      await _hiringRepository.updateRequestStatus(
        recruiterId: hire.recruiterId,
        workerId: hire.workerId,
        status: 'session_created',
      );
      debugPrint('[RecruiterProvider] Session created, status updated');
      // Notify the seeker that the job is ready for OTP
      unawaited(NotificationService.sendToUser(
        toUserId: hire.workerId,
        title: 'Job Session Started 🔑',
        body: 'Your OTP is ready. ${hire.recruiterName} is waiting.',
        data: {'type': 'otp_ready', 'jobId': hire.jobId},
      ));
      return session;
    } catch (e) {
      debugPrint('[RecruiterProvider] startWork error: $e');
      error = 'Failed to start work session';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── STEP 8: Pay ──────────────────────────────────────────────────────────

  Future<bool> launchPayment({
    required String jobId,
    required String workerName,
    required String upiId,
    required int amount,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    debugPrint('[RecruiterProvider] launchPayment jobId=$jobId amount=$amount '
        'upiId=$upiId');
    try {
      final isVerified = await _isUserVerified(_watchedRecruiterId ?? '');
      if (!isVerified) {
        error = 'Please verify your account to continue';
        return false;
      }
      final matchedSessions = mySessions.where((s) => s.jobId == jobId).toList();
      final session = matchedSessions.isEmpty ? null : matchedSessions.first;
      if (session == null) {
        error = 'Job session not found.';
        return false;
      }
      if (session.status != 'awaiting_payment') {
        error = 'Payment allowed only when job is awaiting payment.';
        return false;
      }
      if (session.isPaid) {
        debugPrint('[RecruiterProvider] Duplicate payment prevented for jobId=$jobId');
        error = 'Payment already completed for this job.';
        return false;
      }

      final launchResult = await PaymentService.payViaUpi(
        upiId: upiId.isNotEmpty ? upiId : 'worker@upi',
        name: workerName,
        amount: amount,
        note: 'LabourLink Payment',
      );
      debugPrint('[RecruiterProvider] payment trigger result '
          'jobId=$jobId launchResult=$launchResult');
      if (launchResult == UpiLaunchResult.launched) {
        return true;
      }
      error = launchResult == UpiLaunchResult.unavailable
          ? 'No UPI app found on this device.'
          : 'Failed to launch UPI payment.';
      return false;
    } catch (e) {
      debugPrint('[RecruiterProvider] launchPayment error: $e');
      error = 'Payment launch failed';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitPaymentResult({
    required String jobId,
    required int amount,
    required bool success,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final isVerified = await _isUserVerified(_watchedRecruiterId ?? '');
      if (!isVerified) {
        error = 'Please verify your account to continue';
        return false;
      }
      final matchedSessions = mySessions.where((s) => s.jobId == jobId).toList();
      final session = matchedSessions.isEmpty ? null : matchedSessions.first;
      if (session == null) {
        error = 'Job session not found.';
        return false;
      }
      if (session.isPaid) {
        error = 'Payment already recorded.';
        return false;
      }

      // Fraud: rapid payment submissions
      final payCooldown = await FraudService.isInCooldown(
        session.recruiterId,
        'submit_payment_$jobId',
        cooldownMs: 15000,
      );
      if (payCooldown) {
        error = 'Please wait before submitting payment again.';
        await FraudService.logEvent(
          userId: session.recruiterId,
          action: 'payment_spam',
          reason: 'Rapid payment submit for jobId=$jobId',
        );
        return false;
      }
      await FraudService.stampAction(
        session.recruiterId,
        'submit_payment_$jobId',
      );
      debugPrint('[RecruiterProvider] payment result jobId=$jobId success=$success');
      if (!success) {
        error = 'Payment failed or was cancelled.';
        return false;
      }

      await _jobSessionRepository.markPaymentCompleted(
        jobId: jobId,
        amount: amount,
        paymentMethod: 'upi',
      );
      await _hiringRepository.updateRequestStatus(
        recruiterId: session.recruiterId,
        workerId: session.workerId,
        status: 'completed',
      );
      debugPrint('[RecruiterProvider] job status update completed for jobId=$jobId');
      // Notify the seeker about payment received
      unawaited(NotificationService.sendToUser(
        toUserId: session.workerId,
        title: 'Payment Received ₹$amount 💰',
        body: 'Payment of ₹$amount received from ${session.recruiterName}.',
        data: {'type': 'payment_received', 'jobId': jobId},
      ));
      return true;
    } catch (e) {
      debugPrint('[RecruiterProvider] submitPaymentResult error: $e');
      error = 'Could not save payment status';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _makeJobId(String recruiterId, String workerId) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${recruiterId}_${workerId}_$ts';
  }

  /// Generates a 4-digit numeric OTP.
  String _generateOtp() {
    final rng = Random.secure();
    final otp = 1000 + rng.nextInt(9000);
    return otp.toString();
  }

  /// Returns the linked session for a hire (if it exists).
  JobSession? sessionForHire(HiringRequest hire) {
    try {
      return mySessions.firstWhere((s) => s.jobId == hire.jobId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isUserVerified(String uid) async {
    if (uid.isEmpty) {
      return false;
    }
    final user = await _userRepository.getUserById(uid);
    final isVerified = user?.isVerified ?? false;
    debugPrint('[RecruiterProvider] verification status uid=$uid verified=$isVerified');
    return isVerified;
  }
}
