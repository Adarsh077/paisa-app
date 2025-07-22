import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:paisa_app/widgets/agent_action.dart';
import 'package:paisa_app/widgets/report_dialog.dart';
import 'package:provider/provider.dart';
import 'agent_provider.dart';

class AgentMessages extends StatefulWidget {
  final ScrollController scrollController;

  const AgentMessages({super.key, required this.scrollController});

  @override
  State<AgentMessages> createState() => _AgentMessagesState();
}

class _AgentMessagesState extends State<AgentMessages> {
  final Set<int> _reportedMessages = <int>{};

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentProvider>(
      builder: (context, agentProvider, child) {
        if (agentProvider.messages.isEmpty) {
          return _buildWelcomeMessage(context);
        }

        return ListView.builder(
          controller: widget.scrollController,
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

            return _buildMessageBubble(
              context,
              msg,
              isUser,
              index,
              agentProvider.messages,
            );
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
    Map<String, dynamic> msg,
    bool isUser,
    int messageIndex,
    List<Map<String, dynamic>> allMessages,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
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
          if (!isUser) _buildReportButton(context, messageIndex, allMessages),
        ],
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

  Widget _buildAssistantMessage(BuildContext context, dynamic content) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (content is Map) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: colorScheme.surfaceContainerLowest,
          child: InkWell(
            onTap: () {
              executeAgentAction(context, content as Map<String, dynamic>);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'View transactions',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      );
    }

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

  Widget _buildReportButton(
    BuildContext context,
    int messageIndex,
    List<Map<String, dynamic>> allMessages,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isReported = _reportedMessages.contains(messageIndex);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (isReported)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reported',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            IconButton(
              onPressed:
                  () => _showReportDialog(context, allMessages, messageIndex),
              icon: Icon(
                Icons.report_outlined,
                size: 22,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              // padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              tooltip: 'Report message',
            ),
        ],
      ),
    );
  }

  void _showReportDialog(
    BuildContext context,
    List<Map<String, dynamic>> allMessages,
    int messageIndex,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => ReportDialog(
            messages: allMessages,
            onReportSubmitted: () {
              setState(() {
                _reportedMessages.add(messageIndex);
              });
            },
          ),
    );
  }
}
