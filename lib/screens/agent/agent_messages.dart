import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:provider/provider.dart';
import 'agent_provider.dart';

class AgentMessages extends StatelessWidget {
  final ScrollController scrollController;

  const AgentMessages({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentProvider>(
      builder: (context, agentProvider, child) {
        if (agentProvider.messages.isEmpty) {
          return _buildWelcomeMessage(context);
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount:
              agentProvider.messages.length + (agentProvider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (agentProvider.isLoading &&
                index == agentProvider.messages.length) {
              return _buildLoadingIndicator(context);
            }

            final msg = agentProvider.messages[index];
            final isUser = msg['role'] == 'user';

            return _buildMessageBubble(context, msg, isUser);
          },
        );
      },
    );
  }

  Widget _buildWelcomeMessage(BuildContext context) {
    return Center(
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.tertiary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds);
        },
        blendMode: BlendMode.srcIn,
        child: Text(
          'Hello, Adarsh',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 12,
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Just a second...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, String> msg,
    bool isUser,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding:
              isUser
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                  : EdgeInsets.zero,
          decoration:
              isUser
                  ? BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  )
                  : null,
          child:
              isUser
                  ? _buildUserMessage(context, msg['content']!)
                  : _buildAssistantMessage(context, msg['content']!),
        ),
      ),
    );
  }

  Widget _buildUserMessage(BuildContext context, String content) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      content,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildAssistantMessage(BuildContext context, String content) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MarkdownWidget(
      data: content,
      shrinkWrap: true,
      config: MarkdownConfig.defaultConfig.copy(
        configs: [
          PConfig(
            textStyle:
                theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ) ??
                TextStyle(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
