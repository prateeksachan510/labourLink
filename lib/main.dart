import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/data/repositories/auth_repository_impl.dart';
import 'package:labour_link/data/repositories/certificate_repository_impl.dart';
import 'package:labour_link/data/repositories/chat_repository_impl.dart';
import 'package:labour_link/data/repositories/earnings_repository_impl.dart';
import 'package:labour_link/data/repositories/hiring_repository_impl.dart';
import 'package:labour_link/data/repositories/job_session_repository_impl.dart';
import 'package:labour_link/data/repositories/rating_repository_impl.dart';
import 'package:labour_link/data/repositories/scheduled_booking_repository_impl.dart';
import 'package:labour_link/data/repositories/user_repository_impl.dart';
import 'package:labour_link/data/services/notification_service.dart';
import 'package:labour_link/domain/repositories/auth_repository.dart';
import 'package:labour_link/domain/repositories/certificate_repository.dart';
import 'package:labour_link/domain/repositories/chat_repository.dart';
import 'package:labour_link/domain/repositories/earnings_repository.dart';
import 'package:labour_link/domain/repositories/hiring_repository.dart';
import 'package:labour_link/domain/repositories/job_session_repository.dart';
import 'package:labour_link/domain/repositories/rating_repository.dart';
import 'package:labour_link/domain/repositories/scheduled_booking_repository.dart';
import 'package:labour_link/domain/repositories/user_repository.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/certificate_provider.dart';
import 'package:labour_link/presentation/providers/chat_provider.dart';
import 'package:labour_link/presentation/providers/earnings_provider.dart';
import 'package:labour_link/presentation/providers/job_session_provider.dart';
import 'package:labour_link/presentation/providers/rating_provider.dart';
import 'package:labour_link/presentation/providers/recruiter_provider.dart';
import 'package:labour_link/presentation/providers/scheduled_booking_provider.dart';
import 'package:labour_link/presentation/providers/seeker_provider.dart';
import 'package:labour_link/presentation/screens/common/auth_gate.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize FCM + local notifications
  await NotificationService.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const LabourLinkApp());
}

class LabourLinkApp extends StatelessWidget {
  const LabourLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Repositories ──────────────────────────────────────────────────
        Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        Provider<UserRepository>(create: (_) => UserRepositoryImpl()),
        Provider<HiringRepository>(create: (_) => HiringRepositoryImpl()),
        Provider<JobSessionRepository>(
          create: (_) => JobSessionRepositoryImpl(),
        ),
        Provider<RatingRepository>(create: (_) => RatingRepositoryImpl()),
        Provider<ChatRepository>(create: (_) => ChatRepositoryImpl()),
        Provider<ScheduledBookingRepository>(
          create: (_) => ScheduledBookingRepositoryImpl(),
        ),
        Provider<CertificateRepository>(
          create: (_) => CertificateRepositoryImpl(),
        ),
        Provider<EarningsRepository>(
          create: (_) => EarningsRepositoryImpl(),
        ),

        // ── Providers (ChangeNotifier) ─────────────────────────────────────
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            context.read<AuthRepository>(),
            context.read<UserRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => RecruiterProvider(
            context.read<UserRepository>(),
            context.read<HiringRepository>(),
            context.read<JobSessionRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SeekerProvider(
            context.read<HiringRepository>(),
            context.read<JobSessionRepository>(),
            context.read<UserRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              JobSessionProvider(context.read<JobSessionRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              RatingProvider(context.read<RatingRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ChatProvider(context.read<ChatRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ScheduledBookingProvider(
            context.read<ScheduledBookingRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CertificateProvider(
            context.read<CertificateRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              EarningsProvider(context.read<EarningsRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'LabourLink',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AuthGate(),
      ),
    );
  }
}
