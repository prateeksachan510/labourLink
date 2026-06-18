import 'package:flutter/material.dart';
import 'package:labour_link/data/services/notification_service.dart';
import 'package:labour_link/data/services/scheduled_booking_reminder_service.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/chat_provider.dart';
import 'package:labour_link/presentation/providers/scheduled_booking_provider.dart';
import 'package:labour_link/presentation/providers/seeker_provider.dart';
import 'package:labour_link/presentation/screens/common/booking_history_screen.dart';
import 'package:labour_link/presentation/screens/common/chat_list_screen.dart';
import 'package:labour_link/presentation/screens/common/scheduled_bookings_screen.dart';
import 'package:labour_link/presentation/screens/seeker/seeker_home_screen.dart';
import 'package:labour_link/presentation/screens/seeker/seeker_profile_screen.dart';
import 'package:labour_link/presentation/screens/seeker/seeker_requests_screen.dart';
import 'package:provider/provider.dart';

class SeekerShellScreen extends StatefulWidget {
  const SeekerShellScreen({super.key});

  @override
  State<SeekerShellScreen> createState() => _SeekerShellScreenState();
}

class _SeekerShellScreenState extends State<SeekerShellScreen> {
  int _index = 0;

  // Use IndexedStack so screens are never destroyed — streams stay alive.
  final _screens = const [
    SeekerHomeScreen(),
    SeekerRequestsScreen(),
    BookingHistoryScreen(),
    ScheduledBookingsScreen(),
    ChatListScreen(),
    SeekerProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Start real-time stream once after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<SeekerProvider>().startWatching(user.uid);
        context.read<ChatProvider>().startWatchingRooms(
              uid: user.uid,
              currentUserName: user.name,
            );
        context
            .read<ScheduledBookingProvider>()
            .startWatchingForWorker(user.uid);
        // Save FCM token for this user
        NotificationService.saveFcmToken(user.uid);
        ScheduledBookingReminderService.checkAndSendReminders(
          userId: user.uid,
          isSeeker: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
