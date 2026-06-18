import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/app_card.dart';
import 'package:labour_link/core/widgets/app_text_field.dart';
import 'package:labour_link/core/widgets/gradient_button.dart';
import 'package:labour_link/core/widgets/user_avatar.dart';
import 'package:labour_link/core/widgets/verified_badge.dart';
import 'package:labour_link/data/models/app_user.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/certificate_provider.dart';
import 'package:labour_link/presentation/screens/common/verification_center_screen.dart';
import 'package:labour_link/presentation/screens/seeker/certificates_screen.dart';
import 'package:labour_link/presentation/screens/seeker/earnings_dashboard_screen.dart';
import 'package:provider/provider.dart';

class SeekerProfileScreen extends StatefulWidget {
  const SeekerProfileScreen({super.key});

  @override
  State<SeekerProfileScreen> createState() => _SeekerProfileScreenState();
}

class _SeekerProfileScreenState extends State<SeekerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _profession = TextEditingController();
  final _location = TextEditingController();
  final _bio = TextEditingController();
  final _upiId = TextEditingController();
  final _bankAccountNumber = TextEditingController();
  final _bankIfsc = TextEditingController();
  final _bankAccountName = TextEditingController();

  final _imagePicker = ImagePicker();
  String _paymentMethod = 'cash';
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _profession.dispose();
    _location.dispose();
    _bio.dispose();
    _upiId.dispose();
    _bankAccountNumber.dispose();
    _bankIfsc.dispose();
    _bankAccountName.dispose();
    super.dispose();
  }

  void _initialize(AppUser? user) {
    if (!_initialized && user != null) {
      _name.text = user.name;
      _phone.text = user.phone;
      _profession.text = user.profession;
      _location.text = user.location;
      _bio.text = user.bio;
      _paymentMethod = user.paymentMethod.isNotEmpty ? user.paymentMethod : 'cash';
      _upiId.text = user.upiId;
      _bankAccountNumber.text = user.bankAccountNumber;
      _bankIfsc.text = user.bankIfsc;
      _bankAccountName.text = user.bankAccountName;
      _initialized = true;
    }
  }

  Future<void> _editPhoto() async {
    final auth = context.read<AuthProvider>();
    final source = await showModalBottomSheet<ImageSource>(
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
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final picked = await _imagePicker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;
      final ok = await auth.uploadProfilePhoto(picked);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Photo updated ✓' : (auth.error ?? 'Upload failed')),
          backgroundColor: ok ? AppTheme.success : AppTheme.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AuthProvider>().error ?? 'Could not update photo.',
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    _initialize(user);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: user == null
              ? const Center(
                  child: Text(
                    'Profile not available',
                    style: TextStyle(color: AppTheme.subtle),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile header
                      Row(
                        children: [
                          UserAvatar(user: user, radius: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onBackground,
                                  ),
                                ),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.subtle,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (user.isVerified) const VerifiedBadge(),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: auth.isLoading ? null : _editPhoto,
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              color: AppTheme.primary,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primary.withAlpha(20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                context.read<AuthProvider>().logout(),
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: AppTheme.danger,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.danger.withAlpha(20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Setup',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: _paymentMethod,
                              decoration: const InputDecoration(
                                labelText: 'Payment Method',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'upi', child: Text('UPI')),
                                DropdownMenuItem(
                                  value: 'bank',
                                  child: Text('Bank Transfer'),
                                ),
                                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                              ],
                              onChanged: auth.isLoading
                                  ? null
                                  : (v) => setState(() => _paymentMethod = v ?? 'cash'),
                            ),
                            const SizedBox(height: 12),
                            Form(
                              key: _paymentFormKey,
                              child: Column(
                                children: [
                                  if (_paymentMethod == 'upi')
                                    AppTextField(
                                      controller: _upiId,
                                      label: 'UPI ID',
                                      prefixIcon: Icons.alternate_email_rounded,
                                      validator: (v) {
                                        final text = (v ?? '').trim();
                                        if (text.isEmpty) return 'UPI ID required';
                                        if (!text.contains('@')) {
                                          return 'Invalid UPI ID';
                                        }
                                        return null;
                                      },
                                    ),
                                  if (_paymentMethod == 'bank') ...[
                                    AppTextField(
                                      controller: _bankAccountName,
                                      label: 'Account Holder Name',
                                      prefixIcon: Icons.person_outline,
                                      validator: (v) => (v ?? '').trim().isEmpty
                                          ? 'Name required'
                                          : null,
                                    ),
                                    AppTextField(
                                      controller: _bankAccountNumber,
                                      label: 'Account Number',
                                      prefixIcon: Icons.account_balance_outlined,
                                      keyboardType: TextInputType.number,
                                      validator: (v) => (v ?? '').trim().isEmpty
                                          ? 'Account number required'
                                          : null,
                                    ),
                                    AppTextField(
                                      controller: _bankIfsc,
                                      label: 'IFSC',
                                      prefixIcon: Icons.confirmation_number_outlined,
                                      validator: (v) => (v ?? '').trim().isEmpty
                                          ? 'IFSC required'
                                          : null,
                                    ),
                                    const SizedBox(height: 6),
                                    if (user.bankAccountNumber.isNotEmpty)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Saved: ${user.maskedBankAccountNumber}',
                                          style: const TextStyle(
                                            color: AppTheme.subtle,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                  if (_paymentMethod == 'cash')
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Cash payment requires no setup.',
                                        style: TextStyle(color: AppTheme.subtle),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  GradientButton(
                                    label: 'Save Payment Setup',
                                    icon: Icons.save_outlined,
                                    isLoading: auth.isLoading,
                                    onPressed: auth.isLoading
                                        ? null
                                        : () async {
                                            if (_paymentMethod != 'cash' &&
                                                !_paymentFormKey.currentState!
                                                    .validate()) {
                                              return;
                                            }
                                            final ok = await context
                                                .read<AuthProvider>()
                                                .savePaymentSetup(
                                                  paymentMethod: _paymentMethod,
                                                  upiId: _upiId.text,
                                                  bankAccountNumber:
                                                      _bankAccountNumber.text,
                                                  bankIfsc: _bankIfsc.text,
                                                  bankAccountName:
                                                      _bankAccountName.text,
                                                );
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  ok
                                                      ? 'Payment setup saved ✓'
                                                      : (context
                                                              .read<AuthProvider>()
                                                              .error ??
                                                          'Save failed'),
                                                ),
                                                backgroundColor: ok
                                                    ? AppTheme.success
                                                    : AppTheme.danger,
                                              ),
                                            );
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Certificates Quick Access ─────────────────────────────────
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // Start watching certs for the user
                          final uid = user.uid;
                          context
                              .read<CertificateProvider>()
                              .startWatching(uid);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CertificatesScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFF2A2A4A)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary
                                      .withAlpha(20),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'My Certificates',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppTheme.onBackground,
                                      ),
                                    ),
                                    Text(
                                      'Upload skill & license certificates',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.subtle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.subtle),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Earnings Quick Access ───────────────────────────────────
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const EarningsDashboardScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFF2A2A4A)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.success
                                      .withAlpha(20),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: AppTheme.success,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Earnings Dashboard',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppTheme.onBackground,
                                      ),
                                    ),
                                    Text(
                                      'View income, jobs & ratings',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.subtle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.subtle),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Verification Card ─────────────────────────────────────
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Verification',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _verificationMessage(user),
                              style: const TextStyle(color: AppTheme.subtle),
                            ),
                            if (user.idType.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'ID Type: ${user.idType}',
                                style: const TextStyle(
                                  color: AppTheme.onSurface,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (!user.isVerified)
                              OutlinedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const VerificationCenterScreen(),
                                  ),
                                ),
                                icon: const Icon(Icons.verified_user_outlined),
                                label: Text(
                                  user.hasUploadedId
                                      ? 'View Verification Status'
                                      : 'Verify your account',
                                ),
                              ),
                            if (user.isVerified) const VerifiedBadge(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _name,
                                label: 'Full Name',
                                prefixIcon: Icons.person_outline,
                                validator: (v) =>
                                    v!.isEmpty ? 'Name required' : null,
                              ),
                              AppTextField(
                                controller: _phone,
                                label: 'Phone',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (v) =>
                                    v!.isEmpty ? 'Phone required' : null,
                              ),
                              AppTextField(
                                controller: _profession,
                                label: 'Profession',
                                prefixIcon: Icons.work_outline,
                                validator: (v) =>
                                    v!.isEmpty ? 'Profession required' : null,
                              ),
                              AppTextField(
                                controller: _location,
                                label: 'Location',
                                prefixIcon: Icons.location_on_outlined,
                                validator: (v) =>
                                    v!.isEmpty ? 'Location required' : null,
                              ),
                              AppTextField(
                                controller: _bio,
                                label: 'Bio',
                                prefixIcon: Icons.info_outline,
                                maxLines: 3,
                                validator: (v) =>
                                    v!.isEmpty ? 'Bio required' : null,
                              ),
                              const SizedBox(height: 8),
                              GradientButton(
                                label: 'Save Changes',
                                icon: Icons.save_outlined,
                                isLoading: auth.isLoading,
                                onPressed: auth.isLoading
                                    ? null
                                    : () async {
                                        if (!_formKey.currentState!
                                            .validate()) {
                                          return;
                                        }
                                        await context
                                            .read<AuthProvider>()
                                            .updateProfile(
                                              user.copyWith(
                                                name: _name.text,
                                                phone: _phone.text,
                                                profession: _profession.text,
                                                location: _location.text,
                                                bio: _bio.text,
                                              ),
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Profile updated ✓'),
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  String _verificationMessage(AppUser user) {
    if (!user.hasUploadedId) {
      return 'Verify your account';
    }
    if (user.isVerificationPending) {
      return 'Verification Pending ⏳';
    }
    if (user.isVerified) {
      return 'Verified ✅';
    }
    if (user.isVerificationRejected) {
      return 'Rejected ❌';
    }
    return 'Verification status unavailable';
  }
}
