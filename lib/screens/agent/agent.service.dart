import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../services/auth_service.dart';

class AgentService {
  final AuthService _authService = AuthService();

  AgentService();

  Future<Map<String, dynamic>> chat(List<Map<String, dynamic>> messages) async {
    final url = Uri.parse('${AppConstants.agentBaseUrl}/chat');
    final headers = await _authService.getAuthHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({"messages": messages}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {"role": "assistant", "content": data["response"]};
    } else {
      return {"role": "assistant", "content": "Could not process the request."};
    }
  }
}
