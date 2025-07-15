import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:paisa_app/routes.dart';
import 'package:paisa_app/screens/index.dart';
import 'package:provider/provider.dart';

const agentToFlutterPage = {'search_transactions': transactions};

void executeAgentAction(
  BuildContext? context,
  Map<String, dynamic> action,
) async {
  if (context == null) return;

  if (action['type'] == 'navigate') {
    final routeName = action['data']['name'];
    if (routeName != null && agentToFlutterPage.containsKey(routeName)) {
      final page = agentToFlutterPage[routeName];
      if (page != null) {
        context.read<TransactionsProvider>().clearTransactions();
        Navigator.pushNamed(
          context,
          page,
          arguments:
              action['data']['arguments'] is String
                  ? jsonDecode(action['data']['arguments'] as String)
                      as Map<String, dynamic>
                  : {},
        );
      }
    }
  }
}
