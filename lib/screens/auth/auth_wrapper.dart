import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paisa_app/providers/auth_provider.dart';
import 'package:paisa_app/screens/auth/login_screen.dart';
import 'package:paisa_app/screens/agent/agent.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check auth status when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isInitialLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isAuthenticated) {
          return const AgentScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
