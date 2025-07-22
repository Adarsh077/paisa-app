import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'auth_service.dart';

enum ReportType {
  offensive('offensive', 'Offensive/unsafe'),
  notCorrect('not correct', 'Not factually correct'),
  didntFollow('spam', 'Didn\'t follow instructions'),
  wrongLanguage('inappropriate', 'Wrong language'),
  genericBland('harassment', 'Generic/bland'),
  other('other', 'Other');

  const ReportType(this.value, this.displayName);
  final String value;
  final String displayName;
}

class ReportService {
  final AuthService _authService = AuthService();

  Future<bool> submitReport({
    required ReportType type,
    required String description,
    required List<Map<String, dynamic>> messages,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseUrl}/user-reports');
      final headers = await _authService.getAuthHeaders();

      final body = {
        'type': type.value,
        'description': description.isNotEmpty ? description : null,
        'messages': messages,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error submitting report: $e');
      return false;
    }
  }
}
