import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:paisa_app/widgets/agent_action.dart';
import 'package:provider/provider.dart';
import 'agent.service.dart';
import '../transactions/transactions_provider.dart';

class AgentProvider extends ChangeNotifier {
  final AgentService _agentService = AgentService();
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _cancelRequested = false;
  ScrollController? _scrollController;

  // Getters
  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  TextEditingController get controller => _controller;
  bool get isLoading => _isLoading;
  bool get cancelRequested => _cancelRequested;

  // Set scroll controller for auto-scrolling
  void setScrollController(ScrollController controller) {
    _scrollController = controller;
  }

  // Auto-scroll to bottom
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController?.hasClients == true) {
        _scrollController!.animateTo(
          _scrollController!.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Add a message to the conversation
  void addMessage(Map<String, String> message) {
    _messages.add(message);
    _scrollToBottom();
    notifyListeners();
  }

  // Clear all messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // Send a message
  Future<void> sendMessage([String? message, BuildContext? context]) async {
    final text = message ?? _controller.text.trim();
    if (text.isEmpty) return;

    // If message was provided (from suggestion), set it in the controller
    if (message != null) {
      _controller.text = text;
    }

    // Add user message
    _messages.add({'role': 'user', 'content': text});
    _isLoading = true;
    _cancelRequested = false;
    _controller.clear();
    _scrollToBottom();
    notifyListeners();

    try {
      final messages =
          _messages.map((m) {
            if (m['content'] is Map) {
              m['content'] = jsonEncode(m['content']);
            }
            return m;
          }).toList();
      var response = await _agentService.chat(messages);

      try {
        final responseJson =
            jsonDecode(response['content'] ?? "") as Map<String, dynamic>;
        response['content'] = responseJson;
        executeAgentAction(context, responseJson);
      } catch (e) {
        print(e);
      }

      if (_cancelRequested) {
        _isLoading = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return;
      }

      _messages.add(response);
      _isLoading = false;
      _scrollToBottom();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      // Refetch transactions after successful agent response
      if (context != null && response['content'] is String) {
        try {
          final transactionsProvider = Provider.of<TransactionsProvider>(
            context,
            listen: false,
          );
          await transactionsProvider.refreshTransactions(
            ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>? ??
                {},
          );
        } catch (e) {
          print('Failed to refresh transactions: $e');
        }
      }
    } catch (e) {
      print(e);

      if (_cancelRequested) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      _messages.add({
        'role': 'assistant',
        'content': 'Sorry, something went wrong.',
      });
      _isLoading = false;
      _scrollToBottom();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Stop the current request
  void stopRequest() {
    _isLoading = false;
    _cancelRequested = true;
    notifyListeners();
  }

  // Execute an action (for suggestions)
  void executeAction(Map<String, dynamic> action, [BuildContext? context]) {
    final String type = action['type'];
    final Map<String, dynamic> data = action['data'];

    switch (type) {
      case 'message':
        final String content = data['content'];
        _controller.text = content;
        notifyListeners();
        // Optionally auto-send the message
        // sendMessage(content, context);
        break;
      case 'navigate':
        if (context != null) {
          final String path = data['path'];
          Navigator.of(context).pushNamed(path);
        }
        break;
      default:
        print('Unknown action type: $type');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
