import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/data/models/job_session.dart';
import 'package:labour_link/presentation/providers/seeker_provider.dart';
import 'package:provider/provider.dart';

class OtpConfirmScreen extends StatefulWidget {
  const OtpConfirmScreen({super.key, required this.session});
  final JobSession session;

  @override
  State<OtpConfirmScreen> createState() => _OtpConfirmScreenState();
}

class _OtpConfirmScreenState extends State<OtpConfirmScreen> {
  late final int _otpLength;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _otpLength = widget.session.otp.length == 4 ? 4 : 6;
    _controllers =
        List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _confirm() async {
    if (_otp.length < _otpLength) return;
    final seeker = context.read<SeekerProvider>();
    final ok = await seeker.confirmOtpAndStart(
      jobId: widget.session.jobId,
      enteredOtp: _otp,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _success = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job started successfully! 🎉')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(seeker.error ?? 'Incorrect OTP'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _completeJob() async {
    await context.read<SeekerProvider>().completeJob(
          jobId: widget.session.jobId,
          workerId: widget.session.workerId,
          recruiterId: widget.session.recruiterId,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final seeker = context.watch<SeekerProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
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
                const SizedBox(height: 32),
                const Text(
                  'Enter OTP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask the recruiter for the $_otpLength-digit code to start your job',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.subtle,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                // session info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A2A4A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.session.recruiterName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onBackground,
                              ),
                            ),
                            Text(
                              widget.session.profession,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.subtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                if (!_success) ...[
                  // OTP boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_otpLength, (i) {
                      return Container(
                        width: 46,
                        height: 56,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _controllers[i].text.isNotEmpty
                                ? AppTheme.primary
                                : const Color(0xFF2A2A4A),
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onBackground,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) {
                            setState(() {});
                            if (v.isNotEmpty && i < _otpLength - 1) {
                              _focusNodes[i + 1].requestFocus();
                            }
                            if (v.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: seeker.isLoading || _otp.length < _otpLength
                          ? null
                          : _confirm,
                      child: seeker.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirm & Start Job'),
                    ),
                  ),
                ] else ...[
                  // Success state
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.success.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppTheme.success,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Job Started!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Complete the work and mark it as done below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.subtle,
                          ),
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.task_alt_rounded),
                            label: const Text('Mark Job as Complete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                            ),
                            onPressed: seeker.isLoading ? null : _completeJob,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
