import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/agent_bar.dart';
import 'agent_suggestions.dart';
import 'agent_provider.dart';

class AgentInput extends StatelessWidget {
  const AgentInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentProvider>(
      builder: (context, agentProvider, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AgentSuggestions(
              onActionExecute: (action) {
                // Handle navigation separately if needed
                if (action['type'] == 'navigate') {
                  final String path = action['data']['path'];
                  Navigator.of(context).pushNamed(path);
                } else {
                  agentProvider.executeAction(action, context);
                }
              },
            ),
            const AgentBar(),
          ],
        );
      },
    );
  }
}
