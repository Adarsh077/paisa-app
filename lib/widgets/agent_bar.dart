import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/agent/agent_provider.dart';

class AgentBar extends StatelessWidget {
  final bool standalone;

  const AgentBar({super.key, this.standalone = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<AgentProvider>(
      builder: (context, agentProvider, child) {
        return Hero(
          tag: 'agent_input_field',
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: agentProvider.controller,
                        autofocus: true,
                        enabled: !agentProvider.isLoading,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: _getHintText(agentProvider),
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
                          prefixIcon: _buildPrefixIcon(context, agentProvider),
                          suffixIcon: _buildSuffixIcon(context, agentProvider),
                        ),
                        onSubmitted:
                            (_) => agentProvider.sendMessage(null, context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getHintText(AgentProvider agentProvider) {
    if (standalone) {
      if (agentProvider.isLoading) {
        return 'Just a second...';
      }

      // Get the latest assistant message
      if (agentProvider.messages.isNotEmpty) {
        final latestMessage = agentProvider.messages.lastWhere(
          (msg) => msg['role'] == 'assistant',
          orElse: () => {},
        );
        if (latestMessage.isNotEmpty) {
          String content = latestMessage['content'] ?? '';
          // Limit the placeholder text length and remove line breaks
          content = content.replaceAll('\n', ' ').trim();
          if (content.length > 100) {
            content = '${content.substring(0, 100)}...';
          }
          return content.isNotEmpty ? content : 'Ask me anything';
        }
      }
    }
    return 'Ask me anything';
  }

  Widget? _buildPrefixIcon(BuildContext context, AgentProvider agentProvider) {
    if (standalone && agentProvider.isLoading) {
      final colorScheme = Theme.of(context).colorScheme;
      return SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildSuffixIcon(BuildContext context, AgentProvider agentProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // In standalone mode, don't show stop button when loading
    if (agentProvider.isLoading) {
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
            onPressed: agentProvider.stopRequest,
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
          onPressed: () => agentProvider.sendMessage(null, context),
        ),
      ),
    );
  }
}
