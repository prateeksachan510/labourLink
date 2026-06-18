import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labour_link/data/services/cloudinary_service.dart';

class VerificationService {
  static Future<String> uploadIdProof({
    required String uid,
    required XFile image,
  }) async {
    debugPrint('[VerificationService] uploadIdProof uid=$uid');
    return CloudinaryService.uploadVerificationDocumentFromXFile(
      image,
      uid: uid,
    );
  }
}
