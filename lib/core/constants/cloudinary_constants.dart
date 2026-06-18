/// Cloudinary unsigned upload configuration (no API secret in client).
class CloudinaryConstants {
  CloudinaryConstants._();

  static const String cloudName = 'dmq0couy1';
  static const String uploadPreset = 'labourlink_upload';

  static const String imageUploadUrl =
      'https://api.cloudinary.com/v1_1/dmq0couy1/image/upload';
  static const String rawUploadUrl =
      'https://api.cloudinary.com/v1_1/dmq0couy1/raw/upload';

  static const String folderProfile = 'labourlink/profile_images';
  static const String folderVerification = 'labourlink/verification_docs';
  static const String folderCertificates = 'labourlink/certificates';
}
