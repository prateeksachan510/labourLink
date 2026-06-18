import 'package:flutter/material.dart';
import 'package:labour_link/core/widgets/loading_view.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/screens/auth/login_screen.dart';
import 'package:labour_link/presentation/screens/recruiter/recruiter_shell_screen.dart';
import 'package:labour_link/presentation/screens/seeker/seeker_shell_screen.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading && auth.currentUser == null) {
      return const Scaffold(body: LoadingView());
    }
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }
    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(body: LoadingView(label: 'Fetching profile...'));
    }
    if (user.isSeeker) {
      return const SeekerShellScreen();
    }
    return const RecruiterShellScreen();
  }
}
