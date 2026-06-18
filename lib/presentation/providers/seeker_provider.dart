import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:labour_link/data/models/hiring_request.dart';
import 'package:labour_link/data/models/job_session.dart';
import 'package:labour_link/data/services/fraud_service.dart';
import 'package:labour_link/data/services/location_service.dart';
import 'package:labour_link/data/services/notification_service.dart';
import 'package:labour_link/domain/repositories/hiring_repository.dart';
import 'package:labour_link/domain/repositories/job_session_repository.dart';
import 'package:labour_link/domain/repositories/user_repository.dart';

class SeekerProvider extends ChangeNotifier {
  SeekerProvider(
    this._hiringRepository,
    this._jobSessionRepository,
    this._userRepository,
  );

  final HiringRepository _hiringRepository;
  final JobSessionRepository _jobSessionRepository;
  final UserRepository _userRepository;

  bool isLoading = false;
  String? error;
  List<HiringRequest> requests = [];
  List<JobSession> sessions = [];

  String? _watchedWorkerId;
  StreamSubscription<List<HiringRequest>>? _requestsSub;
  StreamSubscription<List<JobSession>>? _sessionsSub;
  StreamSubscription? _locationSub;
  bool _isTrackingLiveLocation = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Call once when the seeker shell mounts. Subscribes to real-time streams.
  void startWatching(String workerId) {
    if (_watchedWorkerId == workerId) {
      debugPrint('[SeekerProvider] Already watching workerId=$workerId');
      return;
    }
    debugPrint('[SeekerProvider] startWatching workerId=$workerId');
    _watchedWorkerId = workerId;
    _cancelSubs();
    requests = [];
    sessions = [];
    isLoading = true;
    error = null;
    notifyListeners();

    _requestsSub = _hiringRepository.watchWorkerRequests(workerId).listen(
      (data) {
        final filtered = data.where((r) => r.workerId == workerId).toList();
        debugPrint(
          '[SeekerProvider] Requests updated: ${filtered.length} items '
          'uid=$workerId workerId=$workerId recruiterId=n/a',
        );
        requests = filtered;
        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[SeekerProvider] Request stream error: $e');
        error = 'Failed to load requests';
        isLoading = false;
        notifyListeners();
      },
    );

    _sessionsSub = _jobSessionRepository.watchSessionsForWorker(workerId).listen(
      (data) {
        debugPrint('[SeekerProvider] Sessions updated: ${data.length} items');
        sessions = data;
        _syncLiveLocationTracking(workerId);
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[SeekerProvider] Session stream error: $e');
      },
    );
  }

  void stopWatching() {
    debugPrint('[SeekerProvider] stopWatching');
    _watchedWorkerId = null;
    _cancelSubs();
  }

  void _cancelSubs() {
    _requestsSub?.cancel();
    _sessionsSub?.cancel();
    _requestsSub = null;
    _sessionsSub = null;
    _locationSub?.cancel();
    _locationSub = null;
    _isTrackingLiveLocation = false;
  }

  @override
  void dispose() {
    _cancelSubs();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Accept or reject a hiring request.
  Future<void> updateRequest({
    required HiringRequest request,
    required String status,
  }) async {
    debugPrint(
      '[SeekerProvider] updateRequest uid=$_watchedWorkerId '
      'workerId=${request.workerId} recruiterId=${request.recruiterId} '
      'status=$status',
    );
    try {
      final isVerified = await _isCurrentSeekerVerified();
      if (!isVerified) {
        error = 'Please verify your account to continue';
        notifyListeners();
        return;
      }
      if (_watchedWorkerId == null || _watchedWorkerId != request.workerId) {
        error = 'Request does not belong to the current seeker account.';
        notifyListeners();
        return;
      }
      // ── Fraud: rate-limit rejections to prevent spam ────────────────────
      if (status == 'rejected' && _watchedWorkerId != null) {
        final rejectCount = await FraudService.countRecentActions(
          _watchedWorkerId!,
          'reject_request',
          windowMs: 86400000, // 24 hours
        );
        if (rejectCount >= 10) {
          error = 'Too many rejections today. Please try again tomorrow.';
          await FraudService.logEvent(
            userId: _watchedWorkerId!,
            action: 'reject_spam',
            reason: 'Rejected $rejectCount requests in 24h',
          );
          notifyListeners();
          return;
        }
        await FraudService.logEvent(
          userId: _watchedWorkerId!,
          action: 'reject_request',
          reason: 'Rejected request from ${request.recruiterId}',
        );
      }

      await _hiringRepository.updateRequestStatus(
        recruiterId: request.recruiterId,
        workerId: request.workerId,
        status: status,
      );
      // Notify the recruiter about the decision
      if (status == 'accepted' || status == 'rejected') {
        final label = status == 'accepted' ? 'accepted ✅' : 'rejected ❌';
        unawaited(NotificationService.sendToUser(
          toUserId: request.recruiterId,
          title: 'Request $label',
          body: '${request.workerName} has $label your hire request.',
          data: {'type': 'request_$status', 'jobId': request.jobId},
        ));
      }
      // Stream listener will auto-update the list.
    } catch (e) {
      debugPrint('[SeekerProvider] updateRequest error: $e');
      error = 'Failed to update request';
      notifyListeners();
    }
  }

  /// Worker enters OTP → validates and starts the job session.
  Future<bool> confirmOtpAndStart({
    required String jobId,
    required String enteredOtp,
  }) async {
    debugPrint(
      '[SeekerProvider] confirmOtpAndStart jobId=$jobId enteredOtp=$enteredOtp '
      'uid=$_watchedWorkerId workerId=n/a recruiterId=n/a',
    );
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final isVerified = await _isCurrentSeekerVerified();
      if (!isVerified) {
        error = 'Please verify your account to continue';
        return false;
      }
      final session = await _jobSessionRepository.getSession(jobId);
      if (session == null) {
        error = 'Session not found. Ask recruiter to start the job first.';
        debugPrint('[SeekerProvider] Session not found for jobId=$jobId');
        return false;
      }
      debugPrint('[SeekerProvider] Session OTP=${session.otp} '
          'entered=$enteredOtp status=${session.status} '
          'uid=$_watchedWorkerId workerId=${session.workerId} '
          'recruiterId=${session.recruiterId}');
      if (_watchedWorkerId == null || _watchedWorkerId != session.workerId) {
        error = 'This job session belongs to a different seeker account.';
        return false;
      }
      if (await FraudService.hasExceededOtpAttempts(
        userId: session.workerId,
        jobId: jobId,
      )) {
        error =
            'Too many incorrect OTP attempts. Ask the recruiter to restart the session.';
        return false;
      }

      if (session.otp != enteredOtp) {
        await FraudService.recordOtpAttempt(
          userId: session.workerId,
          jobId: jobId,
          success: false,
        );
        error = 'Incorrect OTP. Please check with the recruiter.';
        return false;
      }

      await FraudService.recordOtpAttempt(
        userId: session.workerId,
        jobId: jobId,
        success: true,
      );

      // ── Fraud: OTP expiry check (30 minutes) ────────────────────────────
      if (session.otpCreatedAt.isNotEmpty &&
          FraudService.isOtpExpired(session.otpCreatedAt)) {
        error = 'This OTP has expired. Ask the recruiter to restart the session.';
        await FraudService.logEvent(
          userId: session.workerId,
          action: 'otp_expired',
          reason: 'OTP expired for jobId=${session.jobId}',
        );
        return false;
      }
      await _jobSessionRepository.updateStatus(jobId, 'started');
      await _hiringRepository.updateRequestStatus(
        recruiterId: session.recruiterId,
        workerId: session.workerId,
        status: 'started',
      );
      debugPrint('[SeekerProvider] Job started for jobId=$jobId');
      return true;
    } catch (e) {
      debugPrint('[SeekerProvider] confirmOtpAndStart error: $e');
      error = 'OTP validation failed. Try again.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Worker marks the job as done.
  Future<void> completeJob({
    required String jobId,
    required String workerId,
    required String recruiterId,
  }) async {
    debugPrint(
      '[SeekerProvider] completeJob jobId=$jobId uid=$_watchedWorkerId '
      'workerId=$workerId recruiterId=$recruiterId',
    );
    try {
      final isVerified = await _isCurrentSeekerVerified();
      if (!isVerified) {
        error = 'Please verify your account to continue';
        notifyListeners();
        return;
      }
      await _jobSessionRepository.updateStatus(jobId, 'awaiting_payment');
      await _hiringRepository.updateRequestStatus(
        recruiterId: recruiterId,
        workerId: workerId,
        status: 'awaiting_payment',
      );
      // Notify the recruiter to pay
      unawaited(NotificationService.sendToUser(
        toUserId: recruiterId,
        title: 'Job Complete — Pay Now 💳',
        body: 'Work is done! Please complete the payment.',
        data: {'type': 'job_complete', 'jobId': jobId},
      ));
      debugPrint('[SeekerProvider] completeJob updated to awaiting_payment jobId=$jobId');
    } catch (e) {
      debugPrint('[SeekerProvider] completeJob error: $e');
      error = 'Failed to complete job';
      notifyListeners();
    }
  }

  void _syncLiveLocationTracking(String workerId) {
    final shouldTrack = sessions.any((s) => s.status == 'started');
    if (shouldTrack && !_isTrackingLiveLocation) {
      _startLiveLocationTracking(workerId);
      return;
    }
    if (!shouldTrack && _isTrackingLiveLocation) {
      _stopLiveLocationTracking();
    }
  }

  Future<void> _startLiveLocationTracking(String workerId) async {
    try {
      final permissionGranted = await LocationService.ensurePermission();
      if (!permissionGranted) {
        error = 'Location permission denied. Enable location for live tracking.';
        notifyListeners();
        return;
      }
      debugPrint('[SeekerProvider] Starting live location stream uid=$workerId');
      _isTrackingLiveLocation = true;
      _locationSub?.cancel();
      _locationSub = LocationService.getPositionStream().listen(
        (position) async {
          try {
            debugPrint(
              '[SeekerProvider] current location uid=$workerId lat=${position.latitude} lng=${position.longitude}',
            );
            await _userRepository.updateLiveLocation(
              uid: workerId,
              lat: position.latitude,
              lng: position.longitude,
              updatedAt: DateTime.now().toIso8601String(),
            );
            debugPrint('[SeekerProvider] Firebase location updated uid=$workerId');
          } catch (e) {
            debugPrint('[SeekerProvider] location update error: $e');
          }
        },
        onError: (e) {
          debugPrint('[SeekerProvider] location stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('[SeekerProvider] _startLiveLocationTracking error: $e');
      error = 'Unable to start live location tracking.';
      notifyListeners();
    }
  }

  void _stopLiveLocationTracking() {
    debugPrint('[SeekerProvider] Stopping live location stream');
    _locationSub?.cancel();
    _locationSub = null;
    _isTrackingLiveLocation = false;
  }

  Future<bool> _isCurrentSeekerVerified() async {
    final uid = _watchedWorkerId;
    if (uid == null || uid.isEmpty) {
      return false;
    }
    final user = await _userRepository.getUserById(uid);
    final isVerified = user?.isVerified ?? false;
    debugPrint('[SeekerProvider] verification status uid=$uid verified=$isVerified');
    return isVerified;
  }
}
