import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labour_link/data/models/skill_certificate.dart';
import 'package:labour_link/data/services/fraud_service.dart';
import 'package:labour_link/domain/repositories/certificate_repository.dart';

enum CertificatePickSource { gallery, camera, file }

class CertificateProvider extends ChangeNotifier {
  CertificateProvider(this._repo);
  final CertificateRepository _repo;
  final ImagePicker _imagePicker = ImagePicker();

  List<SkillCertificate> _certificates = [];
  StreamSubscription<List<SkillCertificate>>? _sub;
  bool _isLoading = false;
  String? _error;

  List<SkillCertificate> get certificates => _certificates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get verifiedCount =>
      _certificates.where((c) => c.isVerified).length;

  void startWatching(String uid) {
    _sub?.cancel();
    debugPrint('[CertificateProvider] startWatching uid=$uid');
    _sub = _repo.watchCertificates(uid).listen(
      (list) {
        _certificates = list;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[CertificateProvider] stream error: $e');
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  void stopWatching() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<bool> uploadFromSource({
    required String uid,
    required CertificatePickSource source,
  }) async {
    _error = null;
    notifyListeners();

    String? localPath;
    String fileType = 'image';
    String defaultName = 'Certificate';

    if (source == CertificatePickSource.gallery ||
        source == CertificatePickSource.camera) {
      final picked = await _imagePicker.pickImage(
        source: source == CertificatePickSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return false;
      localPath = picked.path;
      defaultName = picked.name;
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result == null || result.files.isEmpty) return false;
      final file = result.files.first;
      if (file.path == null) return false;
      localPath = file.path!;
      defaultName = file.name;
      fileType = ['jpg', 'jpeg', 'png']
              .contains(file.extension?.toLowerCase() ?? '')
          ? 'image'
          : 'pdf';
    }

    final name = _stripExtension(defaultName);

    final inCooldown = await FraudService.isInCooldown(
      uid,
      'upload_certificate',
      cooldownMs: 10000,
    );
    if (inCooldown) {
      _error = 'Please wait before uploading another certificate.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _repo.uploadCertificate(
        uid: uid,
        localPath: localPath,
        certificateName: name,
        fileType: fileType,
      );
      debugPrint(
          '[CertificateProvider] uploaded certificate name=$name uid=$uid');
      await FraudService.stampAction(uid, 'upload_certificate');
      await FraudService.logEvent(
        userId: uid,
        action: 'certificate_upload',
        reason: 'Uploaded certificate: $name',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[CertificateProvider] upload error: $e');
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCertificate(
      String uid, SkillCertificate cert) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.deleteCertificate(
        uid: uid,
        certificateId: cert.certificateId,
        certificateUrl: cert.certificateUrl,
      );
      debugPrint(
          '[CertificateProvider] deleted certificate certId=${cert.certificateId}');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[CertificateProvider] delete error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<SkillCertificate>> fetchForWorker(String uid) async {
    try {
      return await _repo.getCertificates(uid);
    } catch (e) {
      debugPrint('[CertificateProvider] fetchForWorker error: $e');
      return [];
    }
  }

  String _stripExtension(String name) {
    if (name.contains('.')) {
      return name.substring(0, name.lastIndexOf('.'));
    }
    return name;
  }
}
