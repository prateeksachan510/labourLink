import 'dart:async';

import 'package:flutter/material.dart';
import 'package:labour_link/data/models/scheduled_booking.dart';
import 'package:labour_link/data/services/fraud_service.dart';
import 'package:labour_link/data/services/notification_service.dart';
import 'package:labour_link/domain/repositories/scheduled_booking_repository.dart';
import 'package:uuid/uuid.dart';

class ScheduledBookingProvider extends ChangeNotifier {
  ScheduledBookingProvider(this._repo);
  final ScheduledBookingRepository _repo;

  List<ScheduledBooking> _bookings = [];
  StreamSubscription<List<ScheduledBooking>>? _sub;
  bool _isLoading = false;
  String? _error;

  List<ScheduledBooking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ScheduledBooking> get upcoming => _bookings
      .where((b) => b.isUpcoming && !b.isCancelled && !b.isRejected)
      .toList();

  List<ScheduledBooking> get past => _bookings
      .where((b) => !b.isUpcoming || b.isCancelled || b.isRejected)
      .toList();

  // ── Streaming ─────────────────────────────────────────────────────────────

  void startWatchingForRecruiter(String recruiterId) {
    _sub?.cancel();
    debugPrint(
        '[ScheduledBookingProvider] startWatchingForRecruiter recruiterId=$recruiterId');
    _sub = _repo.watchBookingsForRecruiter(recruiterId).listen(
      (list) {
        _bookings = list;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[ScheduledBookingProvider] stream error: $e');
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  void startWatchingForWorker(String workerId) {
    _sub?.cancel();
    debugPrint(
        '[ScheduledBookingProvider] startWatchingForWorker workerId=$workerId');
    _sub = _repo.watchBookingsForWorker(workerId).listen(
      (list) {
        _bookings = list;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[ScheduledBookingProvider] stream error: $e');
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  void stopWatching() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<bool> createBooking({
    required String recruiterId,
    required String recruiterName,
    required String workerId,
    required String workerName,
    required String profession,
    required DateTime scheduledDateTime,
    required String address,
    String notes = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (scheduledDateTime.isBefore(DateTime.now())) {
        _error = 'Cannot schedule a booking in the past.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final blocked = await FraudService.isUserBlocked(recruiterId);
      if (blocked) {
        _error = 'Your account has been restricted. Contact support.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final inCooldown = await FraudService.isInCooldown(
        recruiterId,
        'schedule_booking',
        cooldownMs: 30000,
      );
      if (inCooldown) {
        _error = 'Please wait before creating another scheduled booking.';
        await FraudService.logEvent(
          userId: recruiterId,
          action: 'schedule_spam',
          reason: 'Rapid scheduled booking creation',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final recentCount = await FraudService.countRecentActions(
        recruiterId,
        'create_scheduled_booking',
        windowMs: 86400000,
      );
      if (recentCount >= 15) {
        _error = 'Daily scheduled booking limit reached. Try again tomorrow.';
        await FraudService.logEvent(
          userId: recruiterId,
          action: 'schedule_daily_limit',
          reason: 'Exceeded 15 scheduled bookings in 24h',
        );
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final bookingId = const Uuid().v4();
      final booking = ScheduledBooking(
        bookingId: bookingId,
        recruiterId: recruiterId,
        recruiterName: recruiterName,
        workerId: workerId,
        workerName: workerName,
        profession: profession,
        scheduledDate:
            '${scheduledDateTime.year.toString().padLeft(4, '0')}-'
            '${scheduledDateTime.month.toString().padLeft(2, '0')}-'
            '${scheduledDateTime.day.toString().padLeft(2, '0')}',
        scheduledTime:
            '${scheduledDateTime.hour.toString().padLeft(2, '0')}:'
            '${scheduledDateTime.minute.toString().padLeft(2, '0')}',
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
        address: address,
        notes: notes,
      );
      debugPrint(
        '[ScheduledBookingProvider] createBooking bookingId=$bookingId '
        'date=${booking.scheduledDate} time=${booking.scheduledTime}',
      );
      await _repo.createBooking(booking);

      await FraudService.stampAction(recruiterId, 'schedule_booking');
      await FraudService.logEvent(
        userId: recruiterId,
        action: 'create_scheduled_booking',
        reason:
            'Scheduled booking for worker=$workerId at ${booking.scheduledDate} ${booking.scheduledTime}',
      );

      // Notify worker via FCM
      await NotificationService.sendToUser(
        toUserId: workerId,
        title: '📅 New Scheduled Booking',
        body:
            '$recruiterName scheduled a job on ${booking.scheduledDate} at ${booking.scheduledTime}',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ScheduledBookingProvider] createBooking error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptBooking(String bookingId, String recruiterId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.updateStatus(bookingId, 'accepted');
      debugPrint(
          '[ScheduledBookingProvider] acceptBooking bookingId=$bookingId');

      // Notify recruiter
      await NotificationService.sendToUser(
        toUserId: recruiterId,
        title: '✅ Booking Accepted',
        body: 'Your scheduled booking has been accepted!',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ScheduledBookingProvider] acceptBooking error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectBooking(String bookingId, String recruiterId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.updateStatus(bookingId, 'rejected');
      debugPrint(
          '[ScheduledBookingProvider] rejectBooking bookingId=$bookingId');

      // Notify recruiter
      await NotificationService.sendToUser(
        toUserId: recruiterId,
        title: '❌ Booking Rejected',
        body: 'Your scheduled booking was not accepted.',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ScheduledBookingProvider] rejectBooking error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.cancelBooking(bookingId);
      debugPrint(
          '[ScheduledBookingProvider] cancelBooking bookingId=$bookingId');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ScheduledBookingProvider] cancelBooking error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
