class HiringRequest {
  const HiringRequest({
    required this.recruiterId,
    required this.workerId,
    required this.recruiterName,
    required this.workerName,
    required this.profession,
    required this.phone,
    required this.status,
    required this.createdAt,
    this.jobId = '',
    this.address = '',
    this.amount = 0,
  });

  final String recruiterId;
  final String workerId;
  final String recruiterName;
  final String workerName;
  final String profession;
  final String phone;
  final String status;
  final String createdAt;
  final String jobId;
  final String address;
  final int amount;

  factory HiringRequest.fromMap(Map<Object?, Object?> map) {
    final createdAt =
        (map['createdAt'] ?? map['timestamp'] ?? '').toString();
    final workerName = (map['workerName'] ?? map['name'] ?? '').toString();
    return HiringRequest(
      recruiterId: (map['recruiterId'] ?? '').toString(),
      workerId: (map['workerId'] ?? '').toString(),
      recruiterName: (map['recruiterName'] ?? '').toString(),
      workerName: workerName,
      profession: (map['profession'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      status: (map['status'] ?? 'pending').toString(),
      createdAt: createdAt,
      jobId: (map['jobId'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      amount: int.tryParse((map['amount'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'recruiterId': recruiterId,
      'workerId': workerId,
      // Keep these two keys for API compatibility with existing app code and task spec.
      'name': workerName,
      'recruiterName': recruiterName,
      'workerName': workerName,
      'profession': profession,
      'phone': phone,
      'status': status,
      'timestamp': createdAt,
      'createdAt': createdAt,
      'jobId': jobId,
      'address': address,
      'amount': amount,
    };
  }

  HiringRequest copyWith({String? status, String? jobId, int? amount}) {
    return HiringRequest(
      recruiterId: recruiterId,
      workerId: workerId,
      recruiterName: recruiterName,
      workerName: workerName,
      profession: profession,
      phone: phone,
      status: status ?? this.status,
      createdAt: createdAt,
      jobId: jobId ?? this.jobId,
      address: address,
      amount: amount ?? this.amount,
    );
  }
}

