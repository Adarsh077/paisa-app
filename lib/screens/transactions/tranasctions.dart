import 'package:flutter/material.dart';
import 'package:paisa_app/screens/transactions/transactions_overview.dart';
import 'package:paisa_app/screens/transactions/transactions.service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionsService _transactionsService = TransactionsService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _allTransactions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _nextCursor;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialTransactions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTransactions();
    }
  }

  Future<void> _loadInitialTransactions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await _transactionsService.getTransactions();
      setState(() {
        _allTransactions = response.transactions;
        _nextCursor = response.pagination.nextCursor;
        _hasMore = response.pagination.hasNext;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _transactionsService.getTransactions(
        cursor: _nextCursor,
      );
      setState(() {
        // Merge new transactions with existing ones
        _mergeTransactions(response.transactions);
        _nextCursor = response.pagination.nextCursor;
        _hasMore = response.pagination.hasNext;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load more transactions')),
        );
      }
    }
  }

  void _mergeTransactions(List<Map<String, dynamic>> newTransactions) {
    for (final newGroup in newTransactions) {
      final date = newGroup['date'];
      final existingGroupIndex = _allTransactions.indexWhere(
        (group) => group['date'] == date,
      );

      if (existingGroupIndex != -1) {
        // Merge transactions for the same date
        final existingTransactions = List<Map<String, dynamic>>.from(
          _allTransactions[existingGroupIndex]['transactions'],
        );
        final newTransactionsList = List<Map<String, dynamic>>.from(
          newGroup['transactions'],
        );
        existingTransactions.addAll(newTransactionsList);
        _allTransactions[existingGroupIndex]['transactions'] =
            existingTransactions;
      } else {
        // Add new date group
        _allTransactions.add(newGroup);
      }
    }

    // Sort by date descending using DateTime
    _allTransactions.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);
      return dateB.compareTo(dateA);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          const TransactionsOverview(),
          const SizedBox(height: 8),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _hasError
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load transactions',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _loadInitialTransactions,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : _allTransactions.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          _allTransactions.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _allTransactions.length) {
                          return Container(
                            padding: const EdgeInsets.all(24.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                          );
                        }

                        final dateGroup = _allTransactions[index];
                        final date = dateGroup['date'];
                        final transactions = dateGroup['transactions'];

                        return _buildDateGroup(context, date, transactions);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(
    BuildContext context,
    String date,
    List<dynamic> transactions,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              _formatDate(date),
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children:
                  transactions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final txn = entry.value;
                    final isLast = index == transactions.length - 1;

                    return _buildTransactionItem(context, txn, isLast);
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Map<String, dynamic> txn,
    bool isLast,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isIncome = txn['type'] == 'income';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  isIncome
                      ? Colors.green.withOpacity(0.1)
                      : colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : colorScheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn['label']!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (txn['category'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    txn['category']!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            isIncome ? txn['amount']! : '-${txn['amount']!}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isIncome ? Colors.green : colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (dateOnly == today) {
        return 'Today';
      } else if (dateOnly == yesterday) {
        return 'Yesterday';
      } else {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${date.day} ${months[date.month - 1]}, ${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
