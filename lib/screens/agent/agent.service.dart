import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants.dart';

class AgentService {
  AgentService();

  Future<Map<String, dynamic>> chat(List<Map<String, String>> messages) async {
    final url = Uri.parse('${AppConstants.agentBaseUrl}/chat');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
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
