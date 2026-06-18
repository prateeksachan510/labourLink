class SkillCertificate {
  const SkillCertificate({
    required this.certificateId,
    required this.certificateName,
    required this.certificateUrl,
    required this.uploadedAt,
    this.verificationStatus = 'pending',
    this.fileType = 'image',
  });

  final String certificateId;
  final String certificateName;
  final String certificateUrl;
  final String uploadedAt;

  /// pending | verified | rejected
  final String verificationStatus;

  /// image | pdf
  final String fileType;

  /// Spec alias for [certificateName]
  String get title => certificateName;

  /// Spec alias for [certificateUrl]
  String get fileUrl => certificateUrl;

  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';

  factory SkillCertificate.fromMap(Map<Object?, Object?> map) {
    final name = (map['certificateName'] ?? map['title'] ?? '').toString();
    final url = (map['certificateUrl'] ?? map['fileUrl'] ?? '').toString();
    return SkillCertificate(
      certificateId: (map['certificateId'] ?? '').toString(),
      certificateName: name,
      certificateUrl: url,
      uploadedAt: (map['uploadedAt'] ?? '').toString(),
      verificationStatus:
          (map['verificationStatus'] ?? 'pending').toString(),
      fileType: (map['fileType'] ?? 'image').toString(),
    );
  }

  Map<String, Object?> toMap() => {
        'certificateId': certificateId,
        'certificateName': certificateName,
        'title': certificateName,
        'certificateUrl': certificateUrl,
        'fileUrl': certificateUrl,
        'uploadedAt': uploadedAt,
        'verificationStatus': verificationStatus,
        'fileType': fileType,
      };
}
