import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:labour_link/core/constants/firebase_paths.dart';
import 'package:labour_link/data/models/scheduled_booking.dart';
import 'package:labour_link/data/services/firebase_service.dart';
import 'package:labour_link/domain/repositories/scheduled_booking_repository.dart';

class ScheduledBookingRepositoryImpl implements ScheduledBookingRepository {
  DatabaseReference get _ref =>
      FirebaseService.db.ref(FirebasePaths.scheduledBookings);

  @override
  Future<void> createBooking(ScheduledBooking booking) async {
    debugPrint(
      '[ScheduledBookingRepo] createBooking bookingId=${booking.bookingId} '
      'recruiterId=${booking.recruiterId} workerId=${booking.workerId} '
      'date=${booking.scheduledDate} time=${booking.scheduledTime}',
    );
    await _ref.child(booking.bookingId).set(booking.toMap());
  }

  @override
  Future<void> updateStatus(String bookingId, String status) async {
    debugPrint(
        '[ScheduledBookingRepo] updateStatus bookingId=$bookingId status=$status');
    await _ref.child(bookingId).update({'status': status});
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    debugPrint('[ScheduledBookingRepo] cancelBooking bookingId=$bookingId');
    await _ref.child(bookingId).update({'status': 'cancelled'});
  }

  @override
  Stream<List<ScheduledBooking>> watchBookingsForRecruiter(
      String recruiterId) {
    debugPrint(
        '[ScheduledBookingRepo] watchBookingsForRecruiter recruiterId=$recruiterId');
    return _ref
        .orderByChild('recruiterId')
        .equalTo(recruiterId)
        .onValue
        .map((event) => _parse(event, 'recruiter=$recruiterId'));
  }

  @override
  Stream<List<ScheduledBooking>> watchBookingsForWorker(String workerId) {
    debugPrint(
        '[ScheduledBookingRepo] watchBookingsForWorker workerId=$workerId');
    return _ref
        .orderByChild('workerId')
        .equalTo(workerId)
        .onValue
        .map((event) => _parse(event, 'worker=$workerId'));
  }

  List<ScheduledBooking> _parse(DatabaseEvent event, String tag) {
    if (!event.snapshot.exists || event.snapshot.value == null) return [];
    final map = (event.snapshot.value as Map).cast<Object?, Object?>();
    final list = map.values
        .map((e) =>
            ScheduledBooking.fromMap((e as Map).cast<Object?, Object?>()))
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    debugPrint('[ScheduledBookingRepo] _parse $tag → ${list.length} bookings');
    return list;
  }
}
