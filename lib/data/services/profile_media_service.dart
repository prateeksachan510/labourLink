import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labour_link/data/services/cloudinary_service.dart';

class ProfileMediaService {
  static Future<String> uploadProfilePhoto({
    required String uid,
    required XFile image,
  }) async {
    debugPrint('[ProfileMediaService] uploadProfilePhoto uid=$uid');
    return CloudinaryService.uploadProfileImageFromXFile(
      image,
      uid: uid,
    );
  }
}
