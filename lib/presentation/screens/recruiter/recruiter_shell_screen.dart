import 'package:flutter/material.dart';
import 'package:labour_link/data/services/notification_service.dart';
import 'package:labour_link/data/services/scheduled_booking_reminder_service.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/chat_provider.dart';
import 'package:labour_link/presentation/providers/recruiter_provider.dart';
import 'package:labour_link/presentation/providers/scheduled_booking_provider.dart';
import 'package:labour_link/presentation/screens/common/booking_history_screen.dart';
import 'package:labour_link/presentation/screens/common/chat_list_screen.dart';
import 'package:labour_link/presentation/screens/common/scheduled_bookings_screen.dart';
import 'package:labour_link/presentation/screens/recruiter/my_hires_screen.dart';
import 'package:labour_link/presentation/screens/recruiter/recruiter_home_screen.dart';
import 'package:labour_link/presentation/screens/recruiter/recruiter_profile_screen.dart';
import 'package:provider/provider.dart';

class RecruiterShellScreen extends StatefulWidget {
  const RecruiterShellScreen({super.key});

  @override
  State<RecruiterShellScreen> createState() => _RecruiterShellScreenState();
}

class _RecruiterShellScreenState extends State<RecruiterShellScreen> {
  int _index = 0;

  // Use IndexedStack so screens are never re-created between tabs.
  final _screens = const [
    RecruiterHomeScreen(),
    MyHiresScreen(),
    BookingHistoryScreen(),
    ScheduledBookingsScreen(),
    ChatListScreen(),
    RecruiterProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<RecruiterProvider>().startWatching(user.uid);
        context.read<ChatProvider>().startWatchingRooms(
              uid: user.uid,
              currentUserName: user.name,
            );
        context
            .read<ScheduledBookingProvider>()
            .startWatchingForRecruiter(user.uid);
        // Save FCM token for this recruiter
        NotificationService.saveFcmToken(user.uid);
        ScheduledBookingReminderService.checkAndSendReminders(
          userId: user.uid,
          isSeeker: false,
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
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'My Hires',
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
