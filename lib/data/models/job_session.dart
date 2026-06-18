class JobSession {
  const JobSession({
    required this.jobId,
    required this.recruiterId,
    required this.workerId,
    required this.recruiterName,
    required this.workerName,
    required this.profession,
    required this.otp,
    required this.status,
    required this.address,
    required this.createdAt,
    this.amount = 0,
    this.upiId = '',
    this.paymentStatus = 'unpaid',
    this.paymentMethod = 'upi',
    this.completedAt = '',
    this.otpCreatedAt = '',
  });

  final String jobId;
  final String recruiterId;
  final String workerId;
  final String recruiterName;
  final String workerName;
  final String profession;
  final String otp;

  /// pending → started → completed → paid
  final String status;
  final String address;
  final String createdAt;
  final int amount;
  final String upiId;
  final String paymentStatus;
  /// upi | bank | cash — set when payment is recorded
  final String paymentMethod;
  final String completedAt;
  /// ISO 8601 timestamp when the OTP session was created. Used for expiry.
  final String otpCreatedAt;

  bool get isPending => status == 'pending';
  bool get isStarted => status == 'started';
  bool get isAwaitingPayment => status == 'awaiting_payment';
  bool get isCompleted => status == 'completed';
  bool get isPaid =>
      paymentStatus == 'paid' || paymentStatus == 'done';

  bool get isPaymentPending =>
      status == 'awaiting_payment' && !isPaid;

  factory JobSession.fromMap(Map<Object?, Object?> map) {
    return JobSession(
      jobId: (map['jobId'] ?? '').toString(),
      recruiterId: (map['recruiterId'] ?? '').toString(),
      workerId: (map['workerId'] ?? '').toString(),
      recruiterName: (map['recruiterName'] ?? '').toString(),
      workerName: (map['workerName'] ?? '').toString(),
      profession: (map['profession'] ?? '').toString(),
      otp: (map['otp'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      address: (map['address'] ?? '').toString(),
      createdAt: (map['createdAt'] ?? '').toString(),
      amount: int.tryParse((map['amount'] ?? '0').toString()) ?? 0,
      upiId: (map['upiId'] ?? '').toString(),
      paymentStatus: (map['paymentStatus'] ?? 'unpaid').toString(),
      paymentMethod: (map['paymentMethod'] ?? 'upi').toString(),
      completedAt: (map['completedAt'] ?? '').toString(),
      otpCreatedAt: (map['otpCreatedAt'] ?? '').toString(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'jobId': jobId,
      'recruiterId': recruiterId,
      'workerId': workerId,
      'recruiterName': recruiterName,
      'workerName': workerName,
      'profession': profession,
      'otp': otp,
      'status': status,
      'address': address,
      'createdAt': createdAt,
      'amount': amount,
      'upiId': upiId,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'completedAt': completedAt,
      'otpCreatedAt': otpCreatedAt,
    };
  }

  JobSession copyWith({
    String? status,
    int? amount,
    String? upiId,
    String? paymentStatus,
    String? paymentMethod,
    String? completedAt,
    String? otpCreatedAt,
  }) {
    return JobSession(
      jobId: jobId,
      recruiterId: recruiterId,
      workerId: workerId,
      recruiterName: recruiterName,
      workerName: workerName,
      profession: profession,
      otp: otp,
      status: status ?? this.status,
      address: address,
      createdAt: createdAt,
      amount: amount ?? this.amount,
      upiId: upiId ?? this.upiId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      completedAt: completedAt ?? this.completedAt,
      otpCreatedAt: otpCreatedAt ?? this.otpCreatedAt,
    );
  }
}
