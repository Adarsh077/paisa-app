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

  Future<void> _refreshTransactions() async {
    setState(() {
      _allTransactions.clear();
      _nextCursor = null;
      _hasMore = true;
    });
    await _loadInitialTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Transactions')),
      body: RefreshIndicator(
        onRefresh: _refreshTransactions,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load transactions'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInitialTransactions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : _allTransactions.isEmpty
                ? const Center(child: Text('No transactions found.'))
                : Column(
                  children: [
                    const TransactionsOverview(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount:
                            _allTransactions.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _allTransactions.length) {
                            // Loading indicator at the bottom
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final dateGroup = _allTransactions[index];
                          final date = dateGroup['date'];
                          final transactions = dateGroup['transactions'];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 16.0,
                                ),
                                width: double.infinity,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainer,
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
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
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
                                              : Theme.of(
                                                context,
                                              ).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
