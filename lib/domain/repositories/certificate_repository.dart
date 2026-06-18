import 'package:labour_link/data/models/skill_certificate.dart';

abstract class CertificateRepository {
  Future<List<SkillCertificate>> getCertificates(String uid);
  Stream<List<SkillCertificate>> watchCertificates(String uid);
  Future<void> uploadCertificate({
    required String uid,
    required String localPath,
    required String certificateName,
    required String fileType,
  });
  Future<void> deleteCertificate({
    required String uid,
    required String certificateId,
    required String certificateUrl,
  });
}
