import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:paisa_app/background_service.dart';
import 'package:provider/provider.dart';
import 'agent_provider.dart';
import 'agent_messages.dart';
import 'agent_input.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../providers/background_service_status_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/background_service_status_widget.dart';
import '../../routes.dart' as routes;

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getPermission();
    // Set the scroll controller in the provider after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProvider>().setScrollController(_scrollController);
      // Start monitoring background service status
      context.read<BackgroundServiceStatusProvider>().startStatusMonitoring();
    });
  }

  Future<bool> _getPermission() async {
    try {
      FlutterLogs.logThis(
        tag: 'background-process',
        subTag: 'permissions',
        logMessage: 'Requesting permissions for background process',
        level: LogLevel.INFO,
      );

      await requestAllPermissions();

      FlutterLogs.logThis(
        tag: 'background-process',
        subTag: 'permissions',
        logMessage: 'Requesting permissions for notifications',
        level: LogLevel.INFO,
      );

      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      await initializeService();

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Paisa'),
        automaticallyImplyLeading: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: BackgroundServiceStatusWidget(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final authProvider = context.read<AuthProvider>();
                await authProvider.logout();
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(routes.login, (route) => false);
                }
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: AgentMessages(scrollController: _scrollController)),
            const AgentInput(),
          ],
        ),
      ),
    );
  }
}
