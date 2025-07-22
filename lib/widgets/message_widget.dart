import 'package:flutter/material.dart';
import 'report_dialog.dart';

class MessageWidget extends StatefulWidget {
  final Map<String, dynamic> message;
  final List<Map<String, dynamic>> allMessages;
  final bool isAssistant;

  const MessageWidget({
    super.key,
    required this.message,
    required this.allMessages,
    required this.isAssistant,
  });

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  bool _isReported = false;

  void _showReportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => ReportDialog(
            messages: widget.allMessages,
            onReportSubmitted: () {
              setState(() {
                _isReported = true;
              });
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = widget.message['role'] == 'user';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isUser
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.message['content'] ?? '',
              style: TextStyle(
                color:
                    isUser
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (widget.isAssistant && !isUser) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (_isReported)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Reported',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  IconButton(
                    onPressed: _showReportDialog,
                    icon: Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.6,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    tooltip: 'Report message',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
