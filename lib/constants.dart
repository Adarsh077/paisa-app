import 'package:flutter/foundation.dart';

class AppConstants {
  static final String baseUrl =
      kReleaseMode ? 'https://api.production.com' : 'http://192.168.0.104:8001';
  static final String agentBaseUrl =
      kReleaseMode ? 'https://api.production.com' : 'http://192.168.0.104:8002';
}
