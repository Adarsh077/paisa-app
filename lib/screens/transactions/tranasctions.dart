import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paisa_app/screens/transactions/transactions_overview.dart';
import 'package:paisa_app/screens/transactions/transactions_provider.dart';
import 'package:paisa_app/widgets/agent_bar.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  late Animation<Offset> _fabOffsetAnimation;
  double _lastOffset = 0;
  bool _fabVisible = true;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fabOffsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 2),
    ).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsProvider>().loadInitialTransactions();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Auto-hide FAB logic
    final offset = _scrollController.position.pixels;
    if (offset > _lastOffset + 5 && _fabVisible) {
      // Scrolling down
      _fabVisible = false;
      _fabAnimationController.forward();
    } else if (offset < _lastOffset - 5 && !_fabVisible) {
      // Scrolling up
      _fabVisible = true;
      _fabAnimationController.reverse();
    }
    _lastOffset = offset;

    // Existing load more logic
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionsProvider>().loadMoreTransactions().catchError((
        e,
      ) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load more transactions')),
          );
        }
      });
    }
  }

  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<TransactionsProvider>(
      builder: (context, transactionsProvider, child) {
        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Make the overview scroll with the list
                transactionsProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : transactionsProvider.hasError
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
                            onPressed:
                                () =>
                                    transactionsProvider
                                        .loadInitialTransactions(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : transactionsProvider.allTransactions.isEmpty
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
                          transactionsProvider.allTransactions.length +
                          (transactionsProvider.isLoadingMore ? 2 : 1),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Overview at the top
                          return Column(
                            children: [
                              const TransactionsOverview(),
                              const SizedBox(height: 8),
                            ],
                          );
                        }
                        final txIndex = index - 1;
                        if (txIndex ==
                            transactionsProvider.allTransactions.length) {
                          return transactionsProvider.isLoadingMore
                              ? Container(
                                padding: const EdgeInsets.all(24.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              )
                              : SizedBox(height: 100);
                        }
                        if (txIndex ==
                            transactionsProvider.allTransactions.length + 1) {
                          return SizedBox(height: 100);
                        }
                        final dateGroup =
                            transactionsProvider.allTransactions[txIndex];
                        final date = dateGroup['date'];
                        final transactions = dateGroup['transactions'];
                        return _buildDateGroup(context, date, transactions);
                      },
                    ),
                // Floating Voice Assistant Bar with auto-hide
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: SlideTransition(
                    position: _fabOffsetAnimation,
                    child: const AgentBar(standalone: true),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  isIncome
                      ? Colors.green.withOpacity(0.1)
                      : colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : colorScheme.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn['label']!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (txn['tags'] != null &&
                    (txn['tags'] as List).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children:
                        (txn['tags'] as List).map<Widget>((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(
                                0.3,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              tag['label'] ?? '',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
                if (txn['category'] != null) ...[
                  const SizedBox(height: 1),
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
          const SizedBox(width: 12),
          Text(
            isIncome ? txn['amount']! : '-${txn['amount']!}',
            style: theme.textTheme.bodyLarge?.copyWith(
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
