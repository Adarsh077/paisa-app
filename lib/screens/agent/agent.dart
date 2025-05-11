import 'package:flutter/material.dart';
import 'agent.service.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final AgentService _agentService = AgentService();
  bool _isLoading = false;
  bool _cancelRequested = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
      _cancelRequested = false;
      _controller.clear();
    });
    try {
      final response = await _agentService.chat(
        _messages
            .where((msg) => msg['role'] == 'user' || msg['role'] == 'agent')
            .map(
              (msg) => {
                'role': msg['role'] == 'user' ? 'user' : 'assistant',
                'content': msg['text'] ?? '',
              },
            )
            .toList(),
      );
      if (_cancelRequested) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _messages.add({'role': 'agent', 'text': response['content'] ?? ''});
        _isLoading = false;
      });
    } catch (e) {
      if (_cancelRequested) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _messages.add({
          'role': 'agent',
          'text': 'Sorry, something went wrong.',
        });
        _isLoading = false;
      });
    }
  }

  void _stopRequest() {
    setState(() {
      _cancelRequested = true;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Agent')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isLoading && index == _messages.length) {
                    // Show loading indicator as agent message
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  final msg = _messages[index];
                  final isUser = msg['role'] == 'user';
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isUser
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        msg['text']!,
                        style: TextStyle(
                          color:
                              isUser
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Message',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child:
                        _isLoading
                            ? IconButton(
                              icon: Icon(
                                Icons.stop_rounded,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                size: 22,
                              ),
                              onPressed: _stopRequest,
                            )
                            : IconButton(
                              padding: const EdgeInsets.only(left: 3),
                              icon: Icon(
                                Icons.send_rounded,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                size: 22,
                              ),
                              onPressed: _sendMessage,
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
