import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../services/auth_service.dart';

class PaginationInfo {
  final bool hasNext;
  final bool hasPrev;
  final String? nextCursor;
  final String? prevCursor;
  final int total;

  PaginationInfo({
    required this.hasNext,
    required this.hasPrev,
    this.nextCursor,
    this.prevCursor,
    required this.total,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
      nextCursor: json['nextCursor'],
      prevCursor: json['prevCursor'],
      total: json['total'] ?? 0,
    );
  }
}

class TransactionsResponse {
  final List<Map<String, dynamic>> transactions;
  final PaginationInfo pagination;

  TransactionsResponse({required this.transactions, required this.pagination});
}

class TransactionsService {
  final AuthService _authService = AuthService();

  TransactionsService();

  Future<TransactionsResponse> getTransactions({
    String? cursor,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}/transactions').replace(
      queryParameters: {
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
        if (filters != null) ...filters,
      },
    );

    final headers = await _authService.getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to load transactions');
    }

    final responseData = json.decode(response.body);
    final List<dynamic> data = responseData['data'] ?? [];
    final paginationData = responseData['pagination'] ?? {};

    // Group transactions by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final txn in data) {
      final isoDate = txn['date'] ?? '';
      // Extract only the date part (YYYY-MM-DD)
      final date = isoDate.split('T').first;
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add({
        '_id': txn['_id'] ?? '',
        'label': txn['label'] ?? '',
        'amount': '₹${txn['amount']}',
        'type': txn['type'] ?? '',
        'tags': txn['tags'] ?? [],
      });
    }

    // Convert to required format
    final result =
        grouped.entries
            .map((e) => {'date': e.key, 'transactions': e.value})
            .toList();

    // Sort by date descending using DateTime
    result.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);
      return dateB.compareTo(dateA);
    });

    return TransactionsResponse(
      transactions: result,
      pagination: PaginationInfo.fromJson(paginationData),
    );
  }

  // Keep the old method for backward compatibility but fetch all data
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final allTransactions = <Map<String, dynamic>>[];
    String? cursor;

    do {
      final response = await getTransactions(cursor: cursor, limit: 50);

      // Merge transactions by date
      for (final newGroup in response.transactions) {
        final date = newGroup['date'];
        final existingGroupIndex = allTransactions.indexWhere(
          (group) => group['date'] == date,
        );

        if (existingGroupIndex != -1) {
          // Merge transactions for the same date
          final existingTransactions = List<Map<String, dynamic>>.from(
            allTransactions[existingGroupIndex]['transactions'],
          );
          final newTransactions = List<Map<String, dynamic>>.from(
            newGroup['transactions'],
          );
          existingTransactions.addAll(newTransactions);
          allTransactions[existingGroupIndex]['transactions'] =
              existingTransactions;
        } else {
          // Add new date group
          allTransactions.add(newGroup);
        }
      }

      cursor =
          response.pagination.hasNext ? response.pagination.nextCursor : null;
    } while (cursor != null);

    // Sort by date descending using DateTime
    allTransactions.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);
      return dateB.compareTo(dateA);
    });

    return allTransactions;
  }
}
