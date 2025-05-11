import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants.dart';

class TransactionsService {
  TransactionsService();

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final url = Uri.parse('${AppConstants.baseUrl}/transactions');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load transactions');
    }
    final List<dynamic> data = json.decode(response.body);
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
        'label': txn['label'] ?? '',
        'amount': '₹${txn['amount']}',
        'type': txn['type'] ?? '',
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
    return result;
  }
}
