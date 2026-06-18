import 'package:labour_link/data/models/scheduled_booking.dart';

abstract class ScheduledBookingRepository {
  Future<void> createBooking(ScheduledBooking booking);
  Future<void> updateStatus(String bookingId, String status);
  Future<void> cancelBooking(String bookingId);
  Stream<List<ScheduledBooking>> watchBookingsForRecruiter(String recruiterId);
  Stream<List<ScheduledBooking>> watchBookingsForWorker(String workerId);
}
