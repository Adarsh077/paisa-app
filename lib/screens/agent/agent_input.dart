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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AgentSuggestions(onActionExecute: onActionExecute!),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(Icons.stop_rounded, color: colorScheme.error, size: 18),
            onPressed: onStopRequest,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconButton(
          icon: Icon(Icons.send_rounded, color: colorScheme.primary, size: 18),
          onPressed: onSendMessage,
        ),
      ),
    );
  }
}
