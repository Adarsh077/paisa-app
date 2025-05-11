import 'package:flutter/material.dart';
import 'package:paisa_app/screens/transactions/transactions_overview.dart';
import '../../routes.dart' as routes;
import 'package:paisa_app/screens/transactions/transactions.service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    return await TransactionsService().getAllTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Paisa')),
      body: Column(
        children: [
          TransactionsOverview(),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No transactions found.'));
                }
                final transactionsByDate = snapshot.data!;
                return ListView.builder(
                  itemCount: transactionsByDate.length,
                  itemBuilder: (context, dateIndex) {
                    final date = transactionsByDate[dateIndex]['date'];
                    final transactions =
                        transactionsByDate[dateIndex]['transactions'];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          width: double.infinity,
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          child: Text(
                            date,
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        ...transactions.map(
                          (txn) => ListTile(
                            title: Text(
                              txn['label']!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            trailing: Text(
                              txn['type'] == 'income'
                                  ? txn['amount']!
                                  : '-${txn['amount']!}',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    txn['type'] == 'income'
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          Navigator.of(context).pushNamed(routes.agent);
        },
        child: const Icon(Icons.smart_toy), // Changed to AI/robot icon
      ),
    );
  }
}
