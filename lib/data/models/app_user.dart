class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    required this.profession,
    required this.bio,
    required this.location,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.idProofUrl = '',
    this.idType = '',
    this.verificationStatus = '',
    this.profileImageUrl = '',
    this.paymentMethod = '',
    this.upiId = '',
    this.bankAccountNumber = '',
    this.bankIfsc = '',
    this.bankAccountName = '',
  });

  final String uid;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String profession;
  final String bio;
  final String location;
  final double latitude;
  final double longitude;
  final String idProofUrl;
  final String idType;
  final String verificationStatus;
  final String profileImageUrl;
  final String paymentMethod;
  final String upiId;
  final String bankAccountNumber;
  final String bankIfsc;
  final String bankAccountName;

  bool get isSeeker => role.toLowerCase() == 'seeker';
  bool get isRecruiter => role.toLowerCase() == 'recruiter';
  bool get hasUploadedId => idProofUrl.isNotEmpty;
  bool get isVerified => verificationStatus.toLowerCase() == 'verified';
  bool get isVerificationPending => verificationStatus.toLowerCase() == 'pending';
  bool get isVerificationRejected => verificationStatus.toLowerCase() == 'rejected';
  bool get hasProfileImage => profileImageUrl.isNotEmpty;
  bool get hasPaymentMethodConfigured {
    final method = paymentMethod.toLowerCase();
    if (method == 'upi') return upiId.contains('@');
    if (method == 'bank') {
      return bankAccountNumber.isNotEmpty &&
          bankIfsc.isNotEmpty &&
          bankAccountName.isNotEmpty;
    }
    return method == 'cash';
  }

  String get maskedBankAccountNumber {
    if (bankAccountNumber.length <= 4) return bankAccountNumber;
    final last4 = bankAccountNumber.substring(bankAccountNumber.length - 4);
    return 'XXXXXX$last4';
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory AppUser.fromMap(Map<Object?, Object?> map) {
    final locationRaw = map['location'];
    final locationTextRaw = map['locationText'];
    final locationText = locationRaw is String
        ? locationRaw
        : (locationTextRaw ?? '').toString();

    double latitude = 0.0;
    double longitude = 0.0;
    if (locationRaw is Map) {
      final locMap = locationRaw.cast<Object?, Object?>();
      latitude = double.tryParse((locMap['lat'] ?? '0').toString()) ?? 0.0;
      longitude = double.tryParse((locMap['lng'] ?? '0').toString()) ?? 0.0;
    } else {
      latitude = double.tryParse((map['latitude'] ?? '0').toString()) ?? 0.0;
      longitude = double.tryParse((map['longitude'] ?? '0').toString()) ?? 0.0;
    }

    return AppUser(
      uid: (map['uid'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      role: (map['role'] ?? '').toString(),
      profession: (map['profession'] ?? '').toString(),
      bio: (map['bio'] ?? '').toString(),
      location: locationText,
      latitude: latitude,
      longitude: longitude,
      idProofUrl: (map['idProofUrl'] ?? '').toString(),
      idType: (map['idType'] ?? '').toString(),
      verificationStatus: (map['verificationStatus'] ?? '').toString(),
      profileImageUrl: (map['profileImageUrl'] ?? '').toString(),
      paymentMethod: (map['paymentMethod'] ?? '').toString(),
      upiId: (map['upiId'] ?? '').toString(),
      bankAccountNumber: (map['bankAccountNumber'] ?? '').toString(),
      bankIfsc: (map['bankIfsc'] ?? '').toString(),
      bankAccountName: (map['bankAccountName'] ?? '').toString(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'profession': profession,
      'bio': bio,
      'location': location,
      'locationText': location,
      'latitude': latitude,
      'longitude': longitude,
      'idProofUrl': idProofUrl,
      'idType': idType,
      'verificationStatus': verificationStatus,
      'profileImageUrl': profileImageUrl,
      'paymentMethod': paymentMethod,
      'upiId': upiId,
      'bankAccountNumber': bankAccountNumber,
      'bankIfsc': bankIfsc,
      'bankAccountName': bankAccountName,
    };
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? role,
    String? profession,
    String? bio,
    String? location,
    double? latitude,
    double? longitude,
    String? idProofUrl,
    String? idType,
    String? verificationStatus,
    String? profileImageUrl,
    String? paymentMethod,
    String? upiId,
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankAccountName,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profession: profession ?? this.profession,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      idProofUrl: idProofUrl ?? this.idProofUrl,
      idType: idType ?? this.idType,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      upiId: upiId ?? this.upiId,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankAccountName: bankAccountName ?? this.bankAccountName,
    );
  }
}

