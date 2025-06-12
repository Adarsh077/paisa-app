import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

class AgentMessages extends StatelessWidget {
  final List<Map<String, String>> messages;
  final ScrollController scrollController;
  final bool isLoading;

  const AgentMessages({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _buildWelcomeMessage(context);
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(14),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (isLoading && index == messages.length) {
          return _buildLoadingIndicator(context);
        }

        final msg = messages[index];
        final isUser = msg['role'] == 'user';

        return _buildMessageBubble(context, msg, isUser);
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, String> msg,
    bool isUser,
  ) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.symmetric(horizontal: isUser ? 10 : 8, vertical: 8),
        decoration: BoxDecoration(
          color:
              isUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            isUser
                ? _buildUserMessage(context, msg['content']!)
                : _buildAssistantMessage(context, msg['content']!),
      ),
    );
  }

  Widget _buildUserMessage(BuildContext context, String content) {
    return Text(
      content,
      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
    );
  }

  Widget _buildAssistantMessage(BuildContext context, String content) {
    return MarkdownWidget(
      data: content,
      shrinkWrap: true,
      config: MarkdownConfig.defaultConfig.copy(
        configs: [
          PConfig(
            textStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
