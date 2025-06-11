import 'package:flutter/material.dart';
import 'package:paisa_app/screens/transactions/transactions.service.dart';

class TransactionsOverview extends StatefulWidget {
  const TransactionsOverview({super.key});

  @override
  State<TransactionsOverview> createState() => _TransactionsOverviewState();
}

class _TransactionsOverviewState extends State<TransactionsOverview> {
  int _income = 0;
  int _expense = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTotals();
  }

  Future<void> _fetchTotals() async {
    try {
      final data = await TransactionsService().getAllTransactions();
      int income = 0;
      int expense = 0;
      for (final group in data) {
        for (final txn in group['transactions']) {
          final amountStr = (txn['amount'] as String).replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          final amount = int.tryParse(amountStr) ?? 0;
          if (txn['type'] == 'income') {
            income += amount;
          } else if (txn['type'] == 'expense') {
            expense += amount;
          }
        }
      }
      setState(() {
        _income = income;
        _expense = expense;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child:
            _loading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(left: 5),
                            child: Text(
                              'Income',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹ ${_income.toString()}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 28,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: Theme.of(context).dividerColor.withOpacity(0.5),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(left: 5),
                            child: Text(
                              'Expense',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹ ${_expense.toString()}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
