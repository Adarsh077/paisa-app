import 'package:flutter/material.dart';

class AgentSuggestions extends StatelessWidget {
  final Function(Map<String, dynamic>) onActionExecute;

  const AgentSuggestions({super.key, required this.onActionExecute});

  static const List<Map<String, dynamic>> _suggestions = [
    {
      'title': 'View transactions',
      'action': {
        'type': 'navigate',
        'data': {'path': '/transactions'},
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 16),
            ..._suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _SuggestionChip(
                  title: suggestion['title']!,
                  onTap: () => onActionExecute(suggestion['action']!),
                ),
              );
            }),
            SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SuggestionChip({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
