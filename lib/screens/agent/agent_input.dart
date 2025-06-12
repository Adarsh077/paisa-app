import 'package:flutter/material.dart';
import 'agent_suggestions.dart';

class AgentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSendMessage;
  final VoidCallback onStopRequest;
  final Function(Map<String, dynamic>)? onActionExecute;

  const AgentInput({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSendMessage,
    required this.onStopRequest,
    this.onActionExecute,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AgentSuggestions(onActionExecute: onActionExecute!),
        Container(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    filled: false,
                    suffixIcon: _buildSuffixIcon(context),
                  ),
                  onSubmitted: (_) => onSendMessage(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuffixIcon(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton.filledTonal(
          icon: Icon(
            Icons.stop_rounded,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          onPressed: onStopRequest,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: IconButton.filledTonal(
        icon: Icon(
          Icons.send_rounded,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 22,
        ),
        onPressed: onSendMessage,
      ),
    );
  }
}
