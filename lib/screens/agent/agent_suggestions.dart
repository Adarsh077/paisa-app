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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
