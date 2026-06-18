import 'package:flutter/foundation.dart';
import 'package:labour_link/core/constants/firebase_paths.dart';
import 'package:labour_link/data/models/scheduled_booking.dart';
import 'package:labour_link/data/services/firebase_service.dart';
import 'package:labour_link/data/services/notification_service.dart';

/// Sends one-hour-before reminders for accepted upcoming scheduled bookings.
class ScheduledBookingReminderService {
  ScheduledBookingReminderService._();

  static const _reminderLeadMinutes = 60;

  /// Call on app start / shell mount for the given user.
  static Future<void> checkAndSendReminders({
    required String userId,
    required bool isSeeker,
  }) async {
    try {
      final snap = await FirebaseService.db
          .ref(FirebasePaths.scheduledBookings)
          .get();
      if (!snap.exists || snap.value == null) return;

      final now = DateTime.now();
      final raw = (snap.value as Map).cast<Object?, Object?>();

      for (final entry in raw.entries) {
        if (entry.value is! Map) continue;
        final booking = ScheduledBooking.fromMap(
          (entry.value as Map).cast<Object?, Object?>(),
        );

        final isParticipant = isSeeker
            ? booking.workerId == userId
            : booking.recruiterId == userId;
        if (!isParticipant) continue;
        if (!booking.isAccepted || !booking.isUpcoming) continue;

        final scheduled = booking.scheduledDateTime;
        final diffMinutes = scheduled.difference(now).inMinutes;
        if (diffMinutes < 0 || diffMinutes > _reminderLeadMinutes) continue;

        final alreadySent = await _reminderAlreadySent(booking.bookingId);
        if (alreadySent) continue;

        final otherName =
            isSeeker ? booking.recruiterName : booking.workerName;
        await NotificationService.sendToUser(
          toUserId: userId,
          title: '⏰ Scheduled Job Reminder',
          body:
              'Your job with $otherName starts at ${booking.scheduledTime} '
              'on ${booking.scheduledDate}.',
          data: {
            'type': 'scheduled_reminder',
            'bookingId': booking.bookingId,
          },
        );

        await _markReminderSent(booking.bookingId);
        debugPrint(
          '[ScheduledBookingReminder] sent reminder bookingId=${booking.bookingId} '
          'userId=$userId diffMinutes=$diffMinutes',
        );
      }
    } catch (e) {
      debugPrint('[ScheduledBookingReminder] checkAndSendReminders error: $e');
    }
  }

  static Future<bool> _reminderAlreadySent(String bookingId) async {
    try {
      final snap = await FirebaseService.db
          .ref('${FirebasePaths.scheduledBookings}/$bookingId/reminderSent')
          .get();
      return snap.exists && snap.value == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _markReminderSent(String bookingId) async {
    try {
      await FirebaseService.db
          .ref('${FirebasePaths.scheduledBookings}/$bookingId')
          .update({'reminderSent': true});
    } catch (e) {
      debugPrint('[ScheduledBookingReminder] markReminderSent error: $e');
    }
  }
}
