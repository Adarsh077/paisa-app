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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child:
          _loading
              ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
              : Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Total Income',
                          '₹${_formatAmount(_income)}',
                          Colors.green,
                          Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Total Expense',
                          '₹${_formatAmount(_expense)}',
                          colorScheme.error,
                          Icons.trending_down,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toString();
    }
  }
}
