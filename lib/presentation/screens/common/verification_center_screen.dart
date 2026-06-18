import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/gradient_button.dart';
import 'package:labour_link/core/widgets/user_avatar.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Full-featured Verification Center accessible from the warning banner,
/// profile screen, and dashboard prompt. Handles all four status states:
/// not_uploaded → pending → verified / rejected.
class VerificationCenterScreen extends StatefulWidget {
  const VerificationCenterScreen({super.key});

  @override
  State<VerificationCenterScreen> createState() =>
      _VerificationCenterScreenState();
}

class _VerificationCenterScreenState extends State<VerificationCenterScreen> {
  final _picker = ImagePicker();
  final _idTypes = const ['Aadhaar', 'Voter ID', 'Passport', 'Driving Licence'];
  String _selectedIdType = 'Aadhaar';
  XFile? _pickedIdImage;
  XFile? _pickedPhotoImage;

  // ── Image Pickers ─────────────────────────────────────────────────────────

  Future<void> _pickIdImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image == null) return;
      debugPrint('[VerificationCenter] id image selected path=${image.path}');
      setState(() => _pickedIdImage = image);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not open image picker: $e', isError: true);
      debugPrint('[VerificationCenter] id image picker error: $e');
    }
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 90);
      if (image == null) return;
      debugPrint(
        '[VerificationCenter] profile image selected path=${image.path}',
      );
      setState(() => _pickedPhotoImage = image);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not open image picker: $e', isError: true);
      debugPrint('[VerificationCenter] profile picker error: $e');
    }
  }

  // ── Upload Actions ────────────────────────────────────────────────────────

  Future<void> _uploadId() async {
    if (_pickedIdImage == null) {
      _showSnack('Please select an ID image first.', isError: true);
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.submitIdVerification(
      idType: _selectedIdType,
      image: _pickedIdImage!,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _pickedIdImage = null);
      _showSnack('ID uploaded successfully — status is now Pending ⏳');
    } else {
      _showSnack(auth.error ?? 'Upload failed. Please try again.', isError: true);
    }
  }

  Future<void> _uploadProfilePhoto() async {
    if (_pickedPhotoImage == null) {
      _showSnack('Please select a photo first.', isError: true);
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.uploadProfilePhoto(_pickedPhotoImage!);
    if (!mounted) return;
    if (ok) {
      setState(() => _pickedPhotoImage = null);
      _showSnack('Profile photo updated ✓');
    } else {
      _showSnack(auth.error ?? 'Photo upload failed.', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      ),
    );
  }

  // ── Image Source Picker Bottom Sheet ─────────────────────────────────────

  Future<ImageSource?> _showSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.subtle.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: AppTheme.primary),
                ),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppTheme.secondary),
                ),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final status = user?.verificationStatus.toLowerCase() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Center'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: user == null
              ? const Center(
                  child: Text(
                    'Not signed in',
                    style: TextStyle(color: AppTheme.subtle),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ── Status Card ──────────────────────────────────────
                    _StatusCard(status: status, idType: user.idType),
                    const SizedBox(height: 24),

                    // ── Profile Photo Section ────────────────────────────
                    _SectionHeader(
                      icon: Icons.photo_camera_outlined,
                      title: 'Profile Photo',
                      subtitle: user.hasProfileImage
                          ? 'Photo uploaded ✓'
                          : 'Add a clear photo of yourself',
                    ),
                    const SizedBox(height: 12),
                    Center(child: UserAvatar(user: user, radius: 40)),
                    const SizedBox(height: 12),
                    _ImagePickerCard(
                      pickedFile: _pickedPhotoImage,
                      existingLabel: user.hasProfileImage
                          ? 'Current photo saved'
                          : null,
                      onPickCamera: auth.isLoading
                          ? null
                          : () async {
                              final src = await _showSourceSheet();
                              if (src != null) _pickProfilePhoto(src);
                            },
                      onPickGallery: auth.isLoading
                          ? null
                          : () async {
                              final src = await _showSourceSheet();
                              if (src != null) _pickProfilePhoto(src);
                            },
                    ),
                    const SizedBox(height: 12),
                    GradientButton(
                      label: 'Upload Profile Photo',
                      icon: Icons.cloud_upload_outlined,
                      isLoading: auth.isLoading,
                      onPressed:
                          auth.isLoading || _pickedPhotoImage == null
                              ? null
                              : _uploadProfilePhoto,
                    ),
                    const SizedBox(height: 28),

                    // ── ID Proof Section ─────────────────────────────────
                    _SectionHeader(
                      icon: Icons.badge_outlined,
                      title: status == 'verified'
                          ? 'ID Verification — Approved ✅'
                          : status == 'rejected'
                              ? 'ID Verification — Re-upload Required'
                              : 'ID Verification',
                      subtitle: _idSectionSubtitle(status, user.idType),
                    ),
                    const SizedBox(height: 12),

                    // Only show upload form if not verified
                    if (status != 'verified') ...[
                      DropdownButtonFormField<String>(
                        value: _selectedIdType,
                        decoration: const InputDecoration(
                          labelText: 'ID Type',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: _idTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: auth.isLoading
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _selectedIdType = value);
                              },
                      ),
                      const SizedBox(height: 12),
                      _ImagePickerCard(
                        pickedFile: _pickedIdImage,
                        existingLabel: user.hasUploadedId
                            ? 'ID previously uploaded — tap below to re-upload'
                            : null,
                        onPickCamera: auth.isLoading
                            ? null
                            : () async {
                                final src = await _showSourceSheet();
                                if (src != null) _pickIdImage(src);
                              },
                        onPickGallery: auth.isLoading
                            ? null
                            : () async {
                                final src = await _showSourceSheet();
                                if (src != null) _pickIdImage(src);
                              },
                      ),
                      const SizedBox(height: 12),
                      GradientButton(
                        label: status == 'rejected'
                            ? 'Re-upload ID Proof'
                            : status == 'pending'
                                ? 'Replace ID Proof'
                                : 'Submit ID for Verification',
                        icon: Icons.verified_user_outlined,
                        isLoading: auth.isLoading,
                        onPressed:
                            auth.isLoading || _pickedIdImage == null
                                ? null
                                : _uploadId,
                      ),
                    ],

                    if (status == 'verified') ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.success.withAlpha(70)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded,
                                color: AppTheme.success, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your account is fully verified. All features are unlocked.',
                                style: TextStyle(color: AppTheme.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── Info Box ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A4A)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppTheme.subtle, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'How Verification Works',
                                style: TextStyle(
                                  color: AppTheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          _InfoPoint(
                              text: 'Upload a clear government-issued photo ID'),
                          _InfoPoint(
                              text:
                                  'Our team reviews your submission within 24 hours'),
                          _InfoPoint(
                              text:
                                  'Once verified, you can hire workers or accept jobs'),
                          _InfoPoint(
                              text:
                                  'You can browse the app freely while pending'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }

  String _idSectionSubtitle(String status, String idType) {
    switch (status) {
      case 'verified':
        return 'ID Type: $idType — Approved by our team';
      case 'pending':
        return 'Under review — usually takes up to 24 hours';
      case 'rejected':
        return 'Your previous submission was rejected. Please re-upload a clear, valid ID.';
      default:
        return 'Upload a government-issued photo ID (Aadhaar, Voter ID, etc.)';
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.idType});

  final String status;
  final String idType;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon, String label, String message) = switch (status) {
      'verified' => (
          AppTheme.success,
          Icons.verified_rounded,
          'Verified',
          'Your account is fully verified. All features are unlocked.',
        ),
      'pending' => (
          AppTheme.warning,
          Icons.hourglass_top_rounded,
          'Pending Review',
          'Your ID is under review. You can still browse the app freely.',
        ),
      'rejected' => (
          AppTheme.danger,
          Icons.cancel_outlined,
          'Verification Rejected',
          'Your ID proof was rejected. Please re-upload a clear, valid document.',
        ),
      _ => (
          AppTheme.subtle,
          Icons.shield_outlined,
          'Not Verified',
          'Upload your ID to unlock hiring and job acceptance features.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.subtle,
                    fontSize: 12,
                  ),
                ),
                if (status == 'verified' && idType.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ID: $idType',
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onBackground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.subtle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.pickedFile,
    required this.onPickCamera,
    required this.onPickGallery,
    this.existingLabel,
  });

  final XFile? pickedFile;
  final VoidCallback? onPickCamera;
  final VoidCallback? onPickGallery;
  final String? existingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                pickedFile != null
                    ? Icons.check_circle_outline
                    : Icons.image_outlined,
                size: 16,
                color: pickedFile != null
                    ? AppTheme.success
                    : AppTheme.subtle,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pickedFile != null
                      ? pickedFile!.name
                      : existingLabel ?? 'No file selected',
                  style: TextStyle(
                    color: pickedFile != null
                        ? AppTheme.onSurface
                        : AppTheme.subtle,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickCamera,
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPoint extends StatelessWidget {
  const _InfoPoint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(color: AppTheme.primary, fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.subtle, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
