import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/gradient_button.dart';
import 'package:labour_link/data/models/app_user.dart';
import 'package:labour_link/data/models/job_session.dart';
import 'package:labour_link/data/models/live_location.dart';
import 'package:labour_link/data/services/directions_service.dart';
import 'package:labour_link/data/services/location_service.dart';
import 'package:labour_link/domain/repositories/user_repository.dart';
import 'package:labour_link/domain/repositories/job_session_repository.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/recruiter_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Shown after recruiter clicks "Start Work" — displays OTP and status.
/// Also shown from My Hires for Pay flow.
class JobSessionScreen extends StatefulWidget {
  const JobSessionScreen({super.key, required this.session});
  final JobSession session;

  @override
  State<JobSessionScreen> createState() => _JobSessionScreenState();
}

class _JobSessionScreenState extends State<JobSessionScreen> {
  late Stream<JobSession?> _stream;
  late Future<AppUser?> _workerFuture;

  @override
  void initState() {
    super.initState();
    // Watch this single session for live status changes.
    _stream = context
        .read<JobSessionRepository>()
        .watchSession(widget.session.jobId);
    _workerFuture = context.read<UserRepository>().getUserById(
          widget.session.workerId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecruiterProvider>();
    final isVerified = context.watch<AuthProvider>().currentUser?.isVerified ?? false;

    return StreamBuilder<JobSession?>(
      stream: _stream,
      initialData: widget.session,
      builder: (context, snap) {
        final session = snap.data ?? widget.session;
        return Scaffold(
          body: Container(
            decoration:
                const BoxDecoration(gradient: AppTheme.backgroundGradient),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back
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
                    const SizedBox(height: 28),

                    // Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withAlpha(80),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              _headerIcon(session.status),
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _headerTitle(session.status),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _headerSubtitle(session.status),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.subtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // OTP box — only shown before job starts
                    if (session.isPending || session.status == 'session_created')
                      _OtpBox(otp: session.otp),

                    // Status info box
                    if (session.isStarted) _StatusBox.started(),
                    if (session.isAwaitingPayment)
                      _StatusBox.awaitingPayment(),
                    if (session.isCompleted && session.paymentStatus != 'paid')
                      _StatusBox.completed(),
                    if (session.paymentStatus == 'paid') _StatusBox.paid(),

                    const SizedBox(height: 24),

                    if (session.isStarted) ...[
                      _EnhancedTrackingMap(workerId: session.workerId),
                      const SizedBox(height: 24),
                    ],

                    // Worker info card
                    _WorkerInfoCard(session: session),
                    const SizedBox(height: 32),

                    // Pay button — visible while awaiting payment
                    if (session.isAwaitingPayment)
                      FutureBuilder<AppUser?>(
                        future: _workerFuture,
                        builder: (context, workerSnap) {
                          final worker = workerSnap.data;
                          final method = (worker?.paymentMethod ?? '').toLowerCase();
                          final canPay = worker?.hasPaymentMethodConfigured ?? false;

                          return Column(
                            children: [
                              if (!isVerified)
                                _WarningBox(
                                  message: 'Please verify your account to continue',
                                ),
                              if (workerSnap.connectionState ==
                                  ConnectionState.waiting)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: CircularProgressIndicator(),
                                ),
                              if (worker != null && !canPay)
                                _WarningBox(
                                  message:
                                      'Worker has not set a payment method yet.',
                                ),
                              if (worker == null)
                                _WarningBox(
                                  message:
                                      'Could not load worker payment details.',
                                ),
                              if (worker != null && method == 'bank' && canPay)
                                _BankDetailsCard(worker: worker),
                              const SizedBox(height: 12),
                              GradientButton(
                                label: _payButtonLabel(method),
                                icon: Icons.currency_rupee_rounded,
                                isLoading: provider.isLoading,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                onPressed: provider.isLoading ||
                                        !isVerified ||
                                        worker == null ||
                                        !canPay
                                    ? null
                                    : () async {
                                        final amount =
                                            await _showAmountDialog(context);
                                        if (amount == null || !context.mounted) {
                                          return;
                                        }

                                        final ok = await _performPaymentFlow(
                                          worker: worker,
                                          session: session,
                                          amount: amount,
                                        );
                                        if (!context.mounted) return;
                                        if (!ok) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                context
                                                        .read<RecruiterProvider>()
                                                        .error ??
                                                    'Payment failed or cancelled',
                                              ),
                                              backgroundColor: AppTheme.danger,
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ],
                          );
                        },
                      ),

                    if (session.paymentStatus == 'paid') ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: AppTheme.success.withAlpha(60)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppTheme.success),
                            const SizedBox(width: 10),
                            Text(
                              'Payment of ₹${session.amount} recorded',
                              style: const TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w600,
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
      },
    );
  }

  IconData _headerIcon(String status) {
    switch (status) {
      case 'started':
        return Icons.work_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'awaiting_payment':
        return Icons.payments_rounded;
      case 'paid':
        return Icons.payments_rounded;
      default:
        return Icons.key_rounded;
    }
  }

  String _headerTitle(String status) {
    switch (status) {
      case 'started':
        return 'Job In Progress';
      case 'completed':
        return 'Job Completed';
      case 'awaiting_payment':
        return 'Awaiting Payment';
      case 'paid':
        return 'Payment Done';
      default:
        return 'Job OTP Ready';
    }
  }

  String _headerSubtitle(String status) {
    switch (status) {
      case 'started':
        return 'The worker has started. Wait for them to finish.';
      case 'completed':
        return 'The work and payment are now closed.';
      case 'awaiting_payment':
        return 'Worker marked completion. Please pay now via UPI.';
      case 'paid':
        return 'Payment has been recorded successfully.';
      default:
        return 'Share this OTP with the worker to begin the job.';
    }
  }

  Future<int?> _showAmountDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Enter Payment Amount',
          style: TextStyle(color: AppTheme.onBackground),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: AppTheme.onBackground),
          decoration: const InputDecoration(
            prefixText: '₹ ',
            hintText: '500',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPaymentResultDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Payment Status',
          style: TextStyle(color: AppTheme.onBackground),
        ),
        content: const Text(
          'Did the payment complete successfully in your UPI app?',
          style: TextStyle(color: AppTheme.subtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Failed/Cancelled'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Payment Success'),
          ),
        ],
      ),
    );
  }

  String _payButtonLabel(String method) {
    switch (method) {
      case 'bank':
        return 'Mark Paid (Bank)';
      case 'cash':
        return 'Mark Paid (Cash)';
      default:
        return 'Pay Now (UPI)';
    }
  }

  Future<bool> _performPaymentFlow({
    required AppUser worker,
    required JobSession session,
    required int amount,
  }) async {
    final dialogContext = context;
    final recruiterProvider = context.read<RecruiterProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final method = worker.paymentMethod.toLowerCase();
    if (method == 'cash') {
      final confirm = await _showConfirmDialog(
        dialogContext,
        title: 'Cash Payment',
        message: 'Have you paid ₹$amount in cash to ${worker.name}?',
        confirmLabel: 'Yes, Paid',
      );
      if (confirm != true) return false;
      final saved = await recruiterProvider.submitPaymentResult(
            jobId: session.jobId,
            amount: amount,
            success: true,
          );
      if (!mounted) return saved;
      if (saved) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Payment saved. Job completed.')),
        );
      }
      return saved;
    }

    if (method == 'bank') {
      final confirm = await _showConfirmDialog(
        dialogContext,
        title: 'Bank Transfer',
        message:
            'Transfer ₹$amount to ${worker.bankAccountName} (${worker.maskedBankAccountNumber}).\n\nConfirm once done.',
        confirmLabel: 'Transfer Done',
      );
      if (confirm != true) return false;
      final saved = await recruiterProvider.submitPaymentResult(
            jobId: session.jobId,
            amount: amount,
            success: true,
          );
      if (!mounted) return saved;
      if (saved) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Payment saved. Job completed.')),
        );
      }
      return saved;
    }

    // Default: UPI
    final ok = await recruiterProvider.launchPayment(
          jobId: session.jobId,
          workerName: session.workerName,
          upiId: worker.upiId,
          amount: amount,
        );
    if (!mounted) return ok;
    if (!ok) return false;

    // ignore: use_build_context_synchronously — dialogContext captured before any await
    final paymentSuccess = await _showPaymentResultDialog(dialogContext);
    if (!mounted || paymentSuccess == null) return false;
    final saved = await recruiterProvider.submitPaymentResult(
          jobId: session.jobId,
          amount: amount,
          success: paymentSuccess,
        );
    if (!mounted) return saved;
    if (saved) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Payment saved. Job completed.')),
      );
    }
    return saved;
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(color: AppTheme.onBackground),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.subtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withAlpha(70)),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.warning)),
    );
  }
}

class _BankDetailsCard extends StatelessWidget {
  const _BankDetailsCard({required this.worker});
  final AppUser worker;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bank Details',
            style: TextStyle(
              color: AppTheme.onBackground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            worker.bankAccountName,
            style: const TextStyle(color: AppTheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'A/c: ${worker.maskedBankAccountNumber}',
            style: const TextStyle(color: AppTheme.subtle),
          ),
          const SizedBox(height: 2),
          Text(
            'IFSC: ${worker.bankIfsc}',
            style: const TextStyle(color: AppTheme.subtle),
          ),
        ],
      ),
    );
  }
}

class _EnhancedTrackingMap extends StatefulWidget {
  const _EnhancedTrackingMap({required this.workerId});
  final String workerId;

  @override
  State<_EnhancedTrackingMap> createState() => _EnhancedTrackingMapState();
}

class _EnhancedTrackingMapState extends State<_EnhancedTrackingMap> {
  LatLng? _recruiterLocation;
  bool _loadingRecruiterLocation = true;
  GoogleMapController? _mapController;
  List<LatLng> _polylinePoints = [];
  double? _etaMinutes;
  double? _distanceKm;
  bool _fetchingRoute = false;

  @override
  void initState() {
    super.initState();
    _initRecruiterLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initRecruiterLocation() async {
    try {
      final permissionGranted = await LocationService.ensurePermission();
      if (!permissionGranted) {
        if (mounted) setState(() => _loadingRecruiterLocation = false);
        return;
      }
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        if (mounted) setState(() => _loadingRecruiterLocation = false);
        return;
      }
      debugPrint(
        '[EnhancedTrackingMap] recruiter location lat=${position.latitude} lng=${position.longitude}',
      );
      if (!mounted) return;
      setState(() {
        _recruiterLocation = LatLng(position.latitude, position.longitude);
        _loadingRecruiterLocation = false;
      });
    } catch (e) {
      debugPrint('[EnhancedTrackingMap] recruiter location error: $e');
      if (mounted) setState(() => _loadingRecruiterLocation = false);
    }
  }

  Future<void> _updateRoute(LatLng workerLatLng) async {
    if (_recruiterLocation == null || _fetchingRoute) return;
    _fetchingRoute = true;
    try {
      final result = await DirectionsService.getRoute(
        origin: _recruiterLocation!,
        destination: workerLatLng,
      );
      debugPrint(
        '[EnhancedTrackingMap] route updated ETA=${result.durationMinutes.toStringAsFixed(0)} min '
        'dist=${result.distanceKm.toStringAsFixed(2)} km '
        'polylinePoints=${result.polylinePoints.length}',
      );
      if (!mounted) return;
      setState(() {
        _polylinePoints = result.polylinePoints;
        _etaMinutes = result.durationMinutes;
        _distanceKm = result.distanceKm;
      });
      // Fit camera to show both markers
      _fitCameraToBounds(workerLatLng);
    } catch (e) {
      debugPrint('[EnhancedTrackingMap] _updateRoute error: $e');
    } finally {
      _fetchingRoute = false;
    }
  }

  void _fitCameraToBounds(LatLng workerLatLng) {
    if (_mapController == null || _recruiterLocation == null) return;
    final southwest = LatLng(
      workerLatLng.latitude < _recruiterLocation!.latitude
          ? workerLatLng.latitude
          : _recruiterLocation!.latitude,
      workerLatLng.longitude < _recruiterLocation!.longitude
          ? workerLatLng.longitude
          : _recruiterLocation!.longitude,
    );
    final northeast = LatLng(
      workerLatLng.latitude > _recruiterLocation!.latitude
          ? workerLatLng.latitude
          : _recruiterLocation!.latitude,
      workerLatLng.longitude > _recruiterLocation!.longitude
          ? workerLatLng.longitude
          : _recruiterLocation!.longitude,
    );
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: southwest, northeast: northeast),
        80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream =
        context.read<UserRepository>().watchLiveLocation(widget.workerId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.navigation_rounded,
                  color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Live Worker Tracking',
                style: TextStyle(
                  color: AppTheme.onBackground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Pulsing live dot
              _LiveDot(),
            ],
          ),
          const SizedBox(height: 12),

          // Map
          SizedBox(
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: StreamBuilder<LiveLocation?>(
                stream: stream,
                builder: (context, snap) {
                  final workerLocation = snap.data;
                  if (_loadingRecruiterLocation) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_recruiterLocation == null || workerLocation == null) {
                    return const Center(
                      child: Text(
                        'Waiting for location updates...',
                        style: TextStyle(color: AppTheme.subtle),
                      ),
                    );
                  }

                  final workerLatLng =
                      LatLng(workerLocation.lat, workerLocation.lng);

                  // Trigger route fetch when worker position changes
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateRoute(workerLatLng);
                  });

                  final markers = <Marker>{
                    Marker(
                      markerId: const MarkerId('recruiter'),
                      position: _recruiterLocation!,
                      infoWindow: const InfoWindow(title: 'You (Recruiter)'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                    ),
                    Marker(
                      markerId: const MarkerId('worker'),
                      position: workerLatLng,
                      infoWindow: const InfoWindow(title: 'Worker'),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                    ),
                  };

                  final polylines = <Polyline>{
                    if (_polylinePoints.isNotEmpty)
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: _polylinePoints,
                        color: AppTheme.primary,
                        width: 4,
                        patterns: [],
                      ),
                  };

                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: workerLatLng,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    markers: markers,
                    polylines: polylines,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                  );
                },
              ),
            ),
          ),

          // ETA + Distance info bar
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A4A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoPill(
                  icon: Icons.straighten_rounded,
                  label: 'Distance',
                  value: _distanceKm != null
                      ? '${_distanceKm!.toStringAsFixed(1)} km'
                      : '—',
                ),
                Container(
                    width: 1, height: 28, color: const Color(0xFF2A2A4A)),
                _InfoPill(
                  icon: Icons.timer_outlined,
                  label: 'ETA',
                  value: _etaMinutes != null
                      ? '${_etaMinutes!.toStringAsFixed(0)} min'
                      : '—',
                ),
                Container(
                    width: 1, height: 28, color: const Color(0xFF2A2A4A)),
                _InfoPill(
                  icon: Icons.directions_car_outlined,
                  label: 'Status',
                  value: 'Live',
                  valueColor: AppTheme.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'LIVE',
            style: TextStyle(
              color: AppTheme.success,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.subtle),
            const SizedBox(width: 3),
            Text(
              label,
              style:
                  const TextStyle(color: AppTheme.subtle, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.onBackground,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}


// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.otp});
  final String otp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A3E), Color(0xFF252550)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primary.withAlpha(80),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              const Text(
                'JOB OTP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.subtle,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                otp,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                  letterSpacing: 12,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Share with the worker to start the job',
                style: TextStyle(fontSize: 12, color: AppTheme.subtle),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tap to copy
        TextButton.icon(
          icon: const Icon(Icons.copy_rounded, size: 14),
          label: const Text('Copy OTP'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: otp));
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.icon, required this.message, required this.color});

  factory _StatusBox.started() => const _StatusBox(
        icon: Icons.work_rounded,
        message: 'Job is in progress…',
        color: AppTheme.warning,
      );
  factory _StatusBox.completed() => const _StatusBox(
        icon: Icons.task_alt_rounded,
        message: 'Job completed successfully.',
        color: AppTheme.success,
      );
  factory _StatusBox.awaitingPayment() => const _StatusBox(
        icon: Icons.payments_outlined,
        message: 'Work completed. Please pay the worker now.',
        color: AppTheme.warning,
      );
  factory _StatusBox.paid() => const _StatusBox(
        icon: Icons.payments_rounded,
        message: 'Payment recorded. Job fully closed.',
        color: AppTheme.primary,
      );

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerInfoCard extends StatelessWidget {
  const _WorkerInfoCard({required this.session});
  final JobSession session;

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
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                session.workerName.isNotEmpty
                    ? session.workerName[0].toUpperCase()
                    : 'W',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.workerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.onBackground,
                  ),
                ),
                Text(
                  session.profession,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.subtle,
                  ),
                ),
                if (session.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    session.address,
                    style:
                        const TextStyle(fontSize: 11, color: AppTheme.subtle),
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
