import 'package:flutter/material.dart';
import 'package:paisa_app/background_service.dart';
import 'agent.service.dart';
import 'agent_messages.dart';
import 'agent_input.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AgentService _agentService = AgentService();
  bool _isLoading = false;
  bool _cancelRequested = false;

  @override
  void initState() {
    super.initState();
    _getPermission();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<bool> _getPermission() async {
    if (await Permission.sms.status != PermissionStatus.granted) {
      await Permission.sms.request();
    }

    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    showNotification('testing notification');

    return true;
  }

  Future<void> _sendMessage([String? message]) async {
    final text = message ?? _controller.text.trim();
    if (text.isEmpty) return;

    // If message was provided (from suggestion), set it in the controller
    if (message != null) {
      _controller.text = text;
    }

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
      _cancelRequested = false;
      _controller.clear();
    });
    _scrollToBottom();
    try {
      final response = await _agentService.chat(_messages);
      if (_cancelRequested) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _messages.add(response);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print(e);
      if (_cancelRequested) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Sorry, something went wrong.',
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _executeAction(Map<String, dynamic> action) {
    final String type = action['type'];
    final Map<String, dynamic> data = action['data'];

    switch (type) {
      case 'message':
        final String content = data['content'];
        _controller.text = content;
        // Optionally auto-send the message
        // _sendMessage(content);
        break;
      case 'navigate':
        final String path = data['path'];
        Navigator.of(context).pushNamed(path);
        break;
      default:
        print('Unknown action type: $type');
    }
  }

  void _stopRequest() {
    setState(() {
      _isLoading = false;
      _cancelRequested = true;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paisa'),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AgentMessages(
                messages: _messages,
                scrollController: _scrollController,
                isLoading: _isLoading,
              ),
            ),
            AgentInput(
              controller: _controller,
              isLoading: _isLoading,
              onSendMessage: _sendMessage,
              onStopRequest: _stopRequest,
              onActionExecute: _executeAction,
            ),
          ],
        ),
      ),
    );
  }
}
