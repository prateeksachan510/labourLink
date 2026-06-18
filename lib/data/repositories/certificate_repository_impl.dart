import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:labour_link/core/constants/firebase_paths.dart';
import 'package:labour_link/data/models/skill_certificate.dart';
import 'package:labour_link/data/services/cloudinary_service.dart';
import 'package:labour_link/data/services/firebase_service.dart';
import 'package:labour_link/domain/repositories/certificate_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class CertificateRepositoryImpl implements CertificateRepository {
  DatabaseReference _certsRef(String uid) =>
      FirebaseService.db.ref('${FirebasePaths.users}/$uid/certificates');

  @override
  Future<List<SkillCertificate>> getCertificates(String uid) async {
    debugPrint('[CertificateRepo] getCertificates uid=$uid');
    final snap = await _certsRef(uid).get();
    return _parseSnapshot(snap);
  }

  @override
  Stream<List<SkillCertificate>> watchCertificates(String uid) {
    debugPrint('[CertificateRepo] watchCertificates uid=$uid');
    return _certsRef(uid).onValue.map((event) {
      final list = _parseSnapshot(event.snapshot);
      debugPrint(
          '[CertificateRepo] watchCertificates emitting ${list.length} for uid=$uid');
      return list;
    });
  }

  @override
  Future<void> uploadCertificate({
    required String uid,
    required String localPath,
    required String certificateName,
    required String fileType,
  }) async {
    final existing = await getCertificates(uid);
    if (existing.any((c) =>
        c.certificateName.toLowerCase() == certificateName.toLowerCase())) {
      debugPrint(
          '[CertificateRepo] uploadCertificate DUPLICATE blocked: $certificateName');
      throw Exception('Certificate "$certificateName" already uploaded.');
    }

    final certId = const Uuid().v4();
    final isPdf = fileType == 'pdf';
    debugPrint(
      '[CertificateRepo] uploadCertificate uid=$uid certId=$certId '
      'name=$certificateName fileType=$fileType',
    );

    File fileToUpload = File(localPath);
    if (!isPdf) {
      try {
        final tempDir = await getTemporaryDirectory();
        final targetPath = '${tempDir.path}/$certId.jpg';
        final compressed = await FlutterImageCompress.compressAndGetFile(
          localPath,
          targetPath,
          quality: 80,
          minWidth: 1024,
          minHeight: 1024,
        );
        if (compressed != null) {
          fileToUpload = File(compressed.path);
        }
      } catch (e) {
        debugPrint('[CertificateRepo] compression failed (using original): $e');
      }
    }

    final downloadUrl = await CloudinaryService.uploadCertificateFile(
      file: fileToUpload,
      uid: uid,
      certId: certId,
      isPdf: isPdf,
    );
    debugPrint('[CertificateRepo] Cloudinary url=$downloadUrl');

    final cert = SkillCertificate(
      certificateId: certId,
      certificateName: certificateName,
      certificateUrl: downloadUrl,
      uploadedAt: DateTime.now().toIso8601String(),
      verificationStatus: 'pending',
      fileType: fileType,
    );
    await _certsRef(uid).child(certId).set(cert.toMap());
    debugPrint('[CertificateRepo] metadata written for certId=$certId');
  }

  @override
  Future<void> deleteCertificate({
    required String uid,
    required String certificateId,
    required String certificateUrl,
  }) async {
    debugPrint(
        '[CertificateRepo] deleteCertificate uid=$uid certId=$certificateId');
    // Cloudinary delete requires server-side API secret — RTDB only.
    await _certsRef(uid).child(certificateId).remove();
    debugPrint(
        '[CertificateRepo] RTDB record removed certId=$certificateId');
  }

  List<SkillCertificate> _parseSnapshot(DataSnapshot snap) {
    if (!snap.exists || snap.value == null) return [];
    final map = (snap.value as Map).cast<Object?, Object?>();
    return map.values
        .map((e) =>
            SkillCertificate.fromMap((e as Map).cast<Object?, Object?>()))
        .toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }
}
