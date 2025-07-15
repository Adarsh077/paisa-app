import 'package:flutter/material.dart';
import 'transactions.service.dart';

class TransactionsProvider extends ChangeNotifier {
  final TransactionsService _transactionsService = TransactionsService();

  // State variables
  List<Map<String, dynamic>> _allTransactions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _nextCursor;
  bool _hasMore = true;

  // Getters
  List<Map<String, dynamic>> get allTransactions =>
      List.unmodifiable(_allTransactions);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasError => _hasError;
  bool get hasMore => _hasMore;
  String? get nextCursor => _nextCursor;

  // Calculate totals from current transactions
  int get totalIncome {
    int income = 0;
    for (final group in _allTransactions) {
      for (final txn in group['transactions']) {
        if (txn['type'] == 'income') {
          final amountStr = (txn['amount'] as String).replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          final amount = int.tryParse(amountStr) ?? 0;
          income += amount;
        }
      }
    }
    return income;
  }

  int get totalExpense {
    int expense = 0;
    for (final group in _allTransactions) {
      for (final txn in group['transactions']) {
        if (txn['type'] == 'expense') {
          final amountStr = (txn['amount'] as String).replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          final amount = int.tryParse(amountStr) ?? 0;
          expense += amount;
        }
      }
    }
    return expense;
  }

  // Load initial transactions
  Future<void> loadInitialTransactions(Map<String, dynamic>? args) async {
    if (_isLoading) return;

    _isLoading = true;
    _hasError = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await _transactionsService.getTransactions(
        filters: args,
      );
      _allTransactions = response.transactions;
      _nextCursor = response.pagination.nextCursor;
      _hasMore = response.pagination.hasNext;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print(e);
      _isLoading = false;
      _hasError = true;
      notifyListeners();
    }
  }

  // Load more transactions for pagination
  Future<void> loadMoreTransactions(Map<String, dynamic>? args) async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _transactionsService.getTransactions(
        cursor: _nextCursor,
        filters: args,
      );
      // Merge new transactions with existing ones
      _mergeTransactions(response.transactions);
      _nextCursor = response.pagination.nextCursor;
      _hasMore = response.pagination.hasNext;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      notifyListeners();
      rethrow; // Re-throw to allow UI to handle error display
    }
  }

  // Merge new transactions with existing ones
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

  // Refresh transactions (pull to refresh)
  Future<void> refreshTransactions(Map<String, dynamic>? args) async {
    // Gather all transaction IDs from current _allTransactions
    List<String> allIds = [];
    for (final group in _allTransactions) {
      for (final txn in group['transactions']) {
        if (txn.containsKey('_id')) {
          allIds.add(txn['_id'].toString());
        }
      }
    }

    try {
      final response = await _transactionsService.getTransactions(
        filters: {'_ids': allIds},
      );
      _allTransactions = response.transactions;
      _nextCursor = response.pagination.nextCursor;
      _hasMore = response.pagination.hasNext;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print(e);
      _isLoading = false;
      _hasError = true;
      notifyListeners();
    }
  }

  // Clear all data
  void clearTransactions() {
    _allTransactions.clear();
    _isLoading = false;
    _isLoadingMore = false;
    _hasError = false;
    _nextCursor = null;
    _hasMore = true;
    notifyListeners();
  }
}
