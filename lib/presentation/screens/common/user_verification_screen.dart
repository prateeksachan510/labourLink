import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/gradient_button.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class UserVerificationScreen extends StatefulWidget {
  const UserVerificationScreen({super.key});

  @override
  State<UserVerificationScreen> createState() => _UserVerificationScreenState();
}

class _UserVerificationScreenState extends State<UserVerificationScreen> {
  final _picker = ImagePicker();
  final _idTypes = const ['Aadhaar', 'VoterID'];
  String _selectedIdType = 'Aadhaar';
  XFile? _pickedImage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image == null) {
        return;
      }
      setState(() => _pickedImage = image);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open image picker.')),
      );
      debugPrint('[UserVerificationScreen] image picker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final image = _pickedImage;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ID Verification'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Upload a valid government ID. Your profile will be marked pending until review.',
                style: TextStyle(color: AppTheme.subtle),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedIdType,
                decoration: const InputDecoration(
                  labelText: 'ID Type',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: _idTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: auth.isLoading
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _selectedIdType = value);
                      },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A4A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      image == null ? 'No image selected' : image.name,
                      style: const TextStyle(color: AppTheme.onBackground),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: auth.isLoading
                                ? null
                                : () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: auth.isLoading
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GradientButton(
                label: 'Upload ID',
                icon: Icons.cloud_upload_outlined,
                isLoading: auth.isLoading,
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        if (_pickedImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select an ID image first.'),
                            ),
                          );
                          return;
                        }
                        final ok = await context
                            .read<AuthProvider>()
                            .submitIdVerification(
                              idType: _selectedIdType,
                              image: _pickedImage!,
                            );
                        if (!context.mounted) return;
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'ID uploaded successfully. Status is now pending.',
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.read<AuthProvider>().error ??
                                    'Upload failed.',
                              ),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
