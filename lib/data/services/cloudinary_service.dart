import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:labour_link/core/constants/cloudinary_constants.dart';
import 'package:path_provider/path_provider.dart';

/// Thrown when a Cloudinary upload fails.
class CloudinaryUploadException implements Exception {
  CloudinaryUploadException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Unsigned Cloudinary uploads — only URLs are stored in Firebase RTDB.
class CloudinaryService {
  CloudinaryService._();

  /// Profile photo → `labourlink/profile_images/{uid}`.
  static Future<String> uploadProfileImage(
    File image, {
    String? uid,
  }) async {
    final file = await _prepareJpegFile(image);
    debugPrint(
      '[CloudinaryService] uploadProfileImage uid=$uid path=${file.path}',
    );
    return _upload(
      file: file,
      uploadUrl: CloudinaryConstants.imageUploadUrl,
      folder: CloudinaryConstants.folderProfile,
      publicId: uid,
    );
  }

  /// Government ID → `labourlink/verification_docs/{uid}`.
  static Future<String> uploadVerificationDocument(
    File image, {
    String? uid,
  }) async {
    final file = await _prepareJpegFile(image);
    debugPrint(
      '[CloudinaryService] uploadVerificationDocument uid=$uid path=${file.path}',
    );
    return _upload(
      file: file,
      uploadUrl: CloudinaryConstants.imageUploadUrl,
      folder: CloudinaryConstants.folderVerification,
      publicId: uid,
    );
  }

  /// Skill certificate image or PDF.
  static Future<String> uploadCertificateFile({
    required File file,
    required String uid,
    required String certId,
    required bool isPdf,
  }) async {
    debugPrint(
      '[CloudinaryService] uploadCertificate uid=$uid certId=$certId isPdf=$isPdf',
    );
    if (isPdf) {
      return _upload(
        file: file,
        uploadUrl: CloudinaryConstants.rawUploadUrl,
        folder: CloudinaryConstants.folderCertificates,
        publicId: '$uid/$certId',
      );
    }
    final jpeg = await _prepareJpegFile(file);
    return _upload(
      file: jpeg,
      uploadUrl: CloudinaryConstants.imageUploadUrl,
      folder: CloudinaryConstants.folderCertificates,
      publicId: '$uid/$certId',
    );
  }

  /// Converts [XFile] from image_picker to a local [File].
  static Future<File> fileFromXFile(XFile xFile) async {
    final path = xFile.path;
    if (path.isNotEmpty && !path.startsWith('content://')) {
      final file = File(path);
      if (await file.exists()) {
        debugPrint('[CloudinaryService] fileFromXFile path=$path');
        return file;
      }
    }
    final bytes = await xFile.readAsBytes();
    if (bytes.isEmpty) {
      throw CloudinaryUploadException('Selected image is empty or unreadable.');
    }
    final tempDir = await getTemporaryDirectory();
    final ext = xFile.name.contains('.')
        ? xFile.name.substring(xFile.name.lastIndexOf('.'))
        : '.jpg';
    final temp = File(
      '${tempDir.path}/pick_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await temp.writeAsBytes(bytes, flush: true);
    debugPrint('[CloudinaryService] fileFromXFile temp=${temp.path}');
    return temp;
  }

  static Future<String> uploadProfileImageFromXFile(
    XFile image, {
    required String uid,
  }) async {
    return uploadProfileImage(await fileFromXFile(image), uid: uid);
  }

  static Future<String> uploadVerificationDocumentFromXFile(
    XFile image, {
    required String uid,
  }) async {
    return uploadVerificationDocument(await fileFromXFile(image), uid: uid);
  }

  static Future<String> _upload({
    required File file,
    required String uploadUrl,
    required String folder,
    String? publicId,
  }) async {
    if (!await file.exists()) {
      throw CloudinaryUploadException('File not found: ${file.path}');
    }

    final uri = Uri.parse(uploadUrl);
    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = CloudinaryConstants.uploadPreset;
    request.fields['folder'] = folder;
    if (publicId != null && publicId.isNotEmpty) {
      request.fields['public_id'] = publicId;
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    );

    debugPrint(
      '[CloudinaryService] POST $uploadUrl preset=${CloudinaryConstants.uploadPreset} '
      'folder=$folder publicId=$publicId',
    );

    try {
      final streamed = await request.send().timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw CloudinaryUploadException(
            'Upload timed out. Check your internet connection.',
          );
        },
      );

      final response = await http.Response.fromStream(streamed);
      debugPrint(
        '[CloudinaryService] response status=${response.statusCode} '
        'bodyLength=${response.body.length}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final msg = _parseErrorMessage(response.body) ??
            'Upload failed (HTTP ${response.statusCode}).';
        throw CloudinaryUploadException(msg);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = (data['secure_url'] ?? data['url'])?.toString() ?? '';
      if (url.isEmpty) {
        throw CloudinaryUploadException(
          'Upload succeeded but no URL was returned.',
        );
      }

      debugPrint('[CloudinaryService] downloadUrl=$url');
      return url;
    } on CloudinaryUploadException {
      rethrow;
    } on SocketException catch (e) {
      debugPrint('[CloudinaryService] SocketException: $e');
      throw CloudinaryUploadException(
        'Network error. Check your connection and try again.',
      );
    } catch (e, st) {
      debugPrint('[CloudinaryService] upload error: $e\n$st');
      if (e is CloudinaryUploadException) rethrow;
      throw CloudinaryUploadException(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  static String? _parseErrorMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        final err = data['error'];
        if (err is Map && err['message'] != null) {
          return err['message'].toString();
        }
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<File> _prepareJpegFile(File source) async {
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        source.path,
        format: CompressFormat.jpeg,
        quality: 80,
        minWidth: 1080,
        minHeight: 1080,
      );
      if (compressed != null && compressed.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final out = File(
          '${tempDir.path}/cloudinary_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await out.writeAsBytes(compressed, flush: true);
        return out;
      }
    } catch (e) {
      debugPrint('[CloudinaryService] compression skipped: $e');
    }
    return source;
  }

  static String formatError(Object error) {
    if (error is CloudinaryUploadException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }
}
