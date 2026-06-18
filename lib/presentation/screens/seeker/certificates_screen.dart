import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/empty_state_view.dart';
import 'package:labour_link/core/widgets/gradient_button.dart';
import 'package:labour_link/data/models/skill_certificate.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/certificate_provider.dart';
import 'package:provider/provider.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().currentUser?.uid;
      if (uid != null) {
        context.read<CertificateProvider>().startWatching(uid);
      }
    });
  }

  Future<void> _uploadCert() async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;

    final source = await showModalBottomSheet<CertificatePickSource>(
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
              const Text(
                'Upload Certificate',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery (image)'),
                onTap: () =>
                    Navigator.pop(ctx, CertificatePickSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera (image)'),
                onTap: () =>
                    Navigator.pop(ctx, CertificatePickSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('File (JPG, PNG, PDF)'),
                onTap: () => Navigator.pop(ctx, CertificatePickSource.file),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    final provider = context.read<CertificateProvider>();
    final ok = await provider.uploadFromSource(uid: uid, source: source);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificate uploaded ✓'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CertificateProvider>();
    final certs = provider.certificates;

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.onBackground),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceVariant,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'My Certificates',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onBackground,
                        ),
                      ),
                    ),
                    if (certs.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${certs.length}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Upload button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GradientButton(
                  label: 'Upload Certificate',
                  icon: Icons.upload_file_rounded,
                  isLoading: provider.isLoading,
                  onPressed: provider.isLoading ? null : _uploadCert,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Supported: JPG, PNG, PDF · Max quality preserved',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.subtle),
                ),
              ),
              const SizedBox(height: 16),

              // List
              Expanded(
                child: certs.isEmpty && !provider.isLoading
                    ? const EmptyStateView(
                        icon: Icons.workspace_premium_rounded,
                        title: 'No certificates yet',
                        subtitle:
                            'Upload your skills and licenses to stand out',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: certs.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _CertCard(
                          cert: certs[i],
                          onDelete: () async {
                            final uid = context
                                .read<AuthProvider>()
                                .currentUser
                                ?.uid;
                            if (uid == null) return;
                            await context
                                .read<CertificateProvider>()
                                .deleteCertificate(uid, certs[i]);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Certificate Card ──────────────────────────────────────────────────────────

class _CertCard extends StatelessWidget {
  const _CertCard({required this.cert, required this.onDelete});
  final SkillCertificate cert;
  final VoidCallback onDelete;

  Color get _statusColor => switch (cert.verificationStatus) {
        'verified' => AppTheme.success,
        'rejected' => AppTheme.danger,
        _ => AppTheme.warning,
      };

  String get _statusLabel => switch (cert.verificationStatus) {
        'verified' => 'Verified ✓',
        'rejected' => 'Rejected',
        _ => 'Pending Review',
      };

  IconData get _fileIcon =>
      cert.fileType == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded;

  String _formatDate(String iso) {
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_fileIcon, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.certificateName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.onBackground,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(cert.uploadedAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.subtle),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surface,
                  title: const Text('Delete Certificate?',
                      style: TextStyle(color: AppTheme.onBackground)),
                  content: Text(
                    'Remove "${cert.certificateName}"?',
                    style: const TextStyle(color: AppTheme.subtle),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) onDelete();
            },
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.danger, size: 20),
          ),
        ],
      ),
    );
  }
}
