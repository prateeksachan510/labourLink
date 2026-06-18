import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/utils/validators.dart';
import 'package:labour_link/core/widgets/app_text_field.dart';
import 'package:labour_link/core/widgets/gradient_button.dart';
import 'package:labour_link/data/services/location_service.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/recruiter_provider.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.role});
  final String role;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _bio = TextEditingController();
  String? _selectedProfession;
  bool _obscure = true;
  bool _locating = false;
  double _lat = 0, _lng = 0;

  bool get _isSeeker => widget.role.toLowerCase() == 'seeker';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _location.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      _lat = pos.latitude;
      _lng = pos.longitude;
      _location.text =
          '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
    }
    if (mounted) setState(() => _locating = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.onBackground,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Create Account',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Register as ${widget.role}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.subtle),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: const Color(0xFF2A2A4A), width: 1),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _name,
                          label: 'Full Name',
                          prefixIcon: Icons.person_outline,
                          validator: (v) =>
                              Validators.required(v, label: 'Name'),
                        ),
                        AppTextField(
                          controller: _email,
                          label: 'Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                        AppTextField(
                          controller: _password,
                          label: 'Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscure,
                          validator: Validators.password,
                          suffix: GestureDetector(
                            onTap: () =>
                                setState(() => _obscure = !_obscure),
                            child: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.subtle,
                              size: 18,
                            ),
                          ),
                        ),
                        AppTextField(
                          controller: _phone,
                          label: 'Phone Number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              Validators.required(v, label: 'Phone'),
                        ),
                        if (_isSeeker) ...[
                          // Profession Dropdown
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: DropdownButtonFormField<String>(
                              value: _selectedProfession,
                              decoration: const InputDecoration(
                                labelText: 'Profession',
                                prefixIcon: Icon(
                                  Icons.work_outline,
                                  color: Color(0xFF8888AA),
                                  size: 20,
                                ),
                              ),
                              dropdownColor: AppTheme.surfaceVariant,
                              style: const TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: 15,
                              ),
                              items: RecruiterProvider.professions
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedProfession = v),
                              validator: (v) =>
                                  v == null ? 'Select a profession' : null,
                            ),
                          ),
                        ],
                        // Location with detect button
                        AppTextField(
                          controller: _location,
                          label: 'City / Location',
                          prefixIcon: Icons.location_on_outlined,
                          validator: (v) =>
                              Validators.required(v, label: 'Location'),
                          suffix: _locating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : GestureDetector(
                                  onTap: _detectLocation,
                                  child: const Icon(
                                    Icons.my_location_rounded,
                                    color: AppTheme.primary,
                                    size: 18,
                                  ),
                                ),
                        ),
                        AppTextField(
                          controller: _bio,
                          label: 'Bio / About',
                          prefixIcon: Icons.info_outline,
                          maxLines: 3,
                          validator: (v) =>
                              Validators.required(v, label: 'Bio'),
                        ),
                        if (auth.error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.danger.withAlpha(60),
                              ),
                            ),
                            child: Text(
                              auth.error!,
                              style: const TextStyle(
                                color: AppTheme.danger,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 8),
                        GradientButton(
                          label: 'Create Account',
                          icon: Icons.person_add_outlined,
                          isLoading: auth.isLoading,
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  final success = await context
                                      .read<AuthProvider>()
                                      .register(
                                        email: _email.text,
                                        password: _password.text,
                                        name: _name.text,
                                        phone: _phone.text,
                                        role: widget.role,
                                        profession:
                                            _selectedProfession ?? '',
                                        location: _location.text,
                                        bio: _bio.text,
                                        latitude: _lat,
                                        longitude: _lng,
                                      );
                                  if (success && context.mounted) {
                                    Navigator.popUntil(
                                      context,
                                      (route) => route.isFirst,
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
}

