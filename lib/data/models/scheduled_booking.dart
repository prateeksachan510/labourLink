class ScheduledBooking {
  const ScheduledBooking({
    required this.bookingId,
    required this.recruiterId,
    required this.recruiterName,
    required this.workerId,
    required this.workerName,
    required this.profession,
    required this.scheduledDate, // 'yyyy-MM-dd'
    required this.scheduledTime, // 'HH:mm'
    required this.status,
    required this.createdAt,
    this.address = '',
    this.notes = '',
    this.reminderSent = false,
  });

  final String bookingId;
  final String recruiterId;
  final String recruiterName;
  final String workerId;
  final String workerName;
  final String profession;
  final String scheduledDate;
  final String scheduledTime;

  /// pending → accepted → rejected → cancelled → completed
  final String status;
  final String createdAt;
  final String address;
  final String notes;
  final bool reminderSent;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  DateTime get scheduledDateTime {
    try {
      final parts = scheduledDate.split('-');
      final timeParts = scheduledTime.split(':');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (_) {
      return DateTime.now();
    }
  }

  bool get isUpcoming => scheduledDateTime.isAfter(DateTime.now());

  factory ScheduledBooking.fromMap(Map<Object?, Object?> map) {
    return ScheduledBooking(
      bookingId: (map['bookingId'] ?? '').toString(),
      recruiterId: (map['recruiterId'] ?? '').toString(),
      recruiterName: (map['recruiterName'] ?? '').toString(),
      workerId: (map['workerId'] ?? '').toString(),
      workerName: (map['workerName'] ?? '').toString(),
      profession: (map['profession'] ?? '').toString(),
      scheduledDate: (map['scheduledDate'] ?? '').toString(),
      scheduledTime: (map['scheduledTime'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      createdAt: (map['createdAt'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      notes: (map['notes'] ?? '').toString(),
      reminderSent: map['reminderSent'] == true,
    );
  }

  Map<String, Object?> toMap() => {
        'bookingId': bookingId,
        'recruiterId': recruiterId,
        'recruiterName': recruiterName,
        'workerId': workerId,
        'workerName': workerName,
        'profession': profession,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'status': status,
        'createdAt': createdAt,
        'address': address,
        'notes': notes,
        'reminderSent': reminderSent,
      };

  ScheduledBooking copyWith({String? status}) => ScheduledBooking(
        bookingId: bookingId,
        recruiterId: recruiterId,
        recruiterName: recruiterName,
        workerId: workerId,
        workerName: workerName,
        profession: profession,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        status: status ?? this.status,
        createdAt: createdAt,
        address: address,
        notes: notes,
      );
}
