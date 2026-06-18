import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/empty_state_view.dart';
import 'package:labour_link/data/models/app_user.dart';
import 'package:labour_link/data/models/skill_certificate.dart';
import 'package:labour_link/presentation/providers/certificate_provider.dart';
import 'package:provider/provider.dart';

class WorkerCertificatesScreen extends StatefulWidget {
  const WorkerCertificatesScreen({super.key, required this.worker});
  final AppUser worker;

  @override
  State<WorkerCertificatesScreen> createState() =>
      _WorkerCertificatesScreenState();
}

class _WorkerCertificatesScreenState
    extends State<WorkerCertificatesScreen> {
  List<SkillCertificate> _certs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCerts();
  }

  Future<void> _loadCerts() async {
    final provider = context.read<CertificateProvider>();
    final list = await provider.fetchForWorker(widget.worker.uid);
    if (mounted) {
      setState(() {
        _certs = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.worker.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onBackground,
                            ),
                          ),
                          const Text(
                            'Skill Certificates',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.subtle),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Certified summary banner
              if (!_loading && _certs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withAlpha(15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.success.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded,
                            color: AppTheme.success, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${_certs.where((c) => c.isVerified).length} verified '
                            '· ${_certs.length} total certificates',
                            style: const TextStyle(
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // List
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary))
                    : _certs.isEmpty
                        ? const EmptyStateView(
                            icon: Icons.workspace_premium_rounded,
                            title: 'No certificates',
                            subtitle:
                                'This worker has not uploaded any certificates yet',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            itemCount: _certs.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) =>
                                _ReadonlyCertCard(cert: _certs[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadonlyCertCard extends StatelessWidget {
  const _ReadonlyCertCard({required this.cert});
  final SkillCertificate cert;

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
            child: Icon(
              cert.fileType == 'pdf'
                  ? Icons.picture_as_pdf_rounded
                  : Icons.image_rounded,
              color: AppTheme.primary,
              size: 24,
            ),
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
                const SizedBox(height: 4),
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
        ],
      ),
    );
  }
}
