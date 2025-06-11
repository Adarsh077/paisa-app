import 'package:flutter/foundation.dart';

class AppConstants {
  static final String baseUrl =
      kReleaseMode
          ? 'http://13.203.202.169:8001'
          : 'http://192.168.25.231:8001';
  static final String agentBaseUrl =
      kReleaseMode
          ? 'http://13.203.202.169:8002'
          : 'http://192.168.25.231:8002';
}
