import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/gradient_button.dart';
import 'package:labour_link/data/models/app_user.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/scheduled_booking_provider.dart';
import 'package:provider/provider.dart';

class ScheduleBookingScreen extends StatefulWidget {
  const ScheduleBookingScreen({super.key, required this.worker});
  final AppUser worker;

  @override
  State<ScheduleBookingScreen> createState() => _ScheduleBookingScreenState();
}

class _ScheduleBookingScreenState extends State<ScheduleBookingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both date and time'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final recruiter = context.read<AuthProvider>().currentUser;
    if (recruiter == null) return;

    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (dt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future date and time'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final ok = await context.read<ScheduledBookingProvider>().createBooking(
          recruiterId: recruiter.uid,
          recruiterName: recruiter.name,
          workerId: widget.worker.uid,
          workerName: widget.worker.name,
          profession: widget.worker.profession,
          scheduledDateTime: dt,
          address: widget.worker.location,
          notes: _notesCtrl.text.trim(),
        );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📅 Booking request sent!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<ScheduledBookingProvider>().error ??
                'Failed to schedule booking',
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduledBookingProvider>();

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
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
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Schedule a Booking',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onBackground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'For ${widget.worker.name} · ${widget.worker.profession}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.subtle),
                ),
                const SizedBox(height: 32),

                // Date picker
                _PickerTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'Select Date',
                  value: _selectedDate == null
                      ? null
                      : DateFormat('EEEE, d MMMM yyyy')
                          .format(_selectedDate!),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 14),

                // Time picker
                _PickerTile(
                  icon: Icons.access_time_rounded,
                  label: 'Select Time',
                  value: _selectedTime?.format(context),
                  onTap: _pickTime,
                ),
                const SizedBox(height: 14),

                // Notes
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFF2A2A4A)),
                  ),
                  child: TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style:
                        const TextStyle(color: AppTheme.onBackground),
                    decoration: InputDecoration(
                      hintText: 'Add notes or special instructions...',
                      hintStyle: const TextStyle(
                          color: AppTheme.subtle, fontSize: 14),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 42),
                        child: Icon(Icons.note_outlined,
                            color: AppTheme.subtle),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Summary
                if (_selectedDate != null && _selectedTime != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.primary.withAlpha(60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Summary',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '📅 ${DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!)}',
                          style: const TextStyle(
                              color: AppTheme.onBackground),
                        ),
                        Text(
                          '⏰ ${_selectedTime!.format(context)}',
                          style: const TextStyle(
                              color: AppTheme.onBackground),
                        ),
                        Text(
                          '👷 ${widget.worker.name}',
                          style: const TextStyle(
                              color: AppTheme.onBackground),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                GradientButton(
                  label: 'Send Booking Request',
                  icon: Icons.send_rounded,
                  isLoading: provider.isLoading,
                  onPressed:
                      provider.isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value != null
                ? AppTheme.primary.withAlpha(80)
                : const Color(0xFF2A2A4A),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.subtle),
                  ),
                  Text(
                    value ?? 'Tap to select',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: value != null
                          ? AppTheme.onBackground
                          : AppTheme.subtle,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: value != null
                  ? AppTheme.primary
                  : AppTheme.subtle,
            ),
          ],
        ),
      ),
    );
  }
}
