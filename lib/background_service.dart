import 'dart:convert';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:readsms/readsms.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';

Future<void> initializeService() async {
  FlutterLogs.logThis(
    tag: 'background-process',
    subTag: 'permissions',
    logMessage: 'Initializing background service',
    level: LogLevel.INFO,
  );

  final service = FlutterBackgroundService();

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      onStart: onStart,
      isForegroundMode: false, // Set to false for background-only execution
      autoStartOnBoot: true,
    ),
  );
  FlutterLogs.logThis(
    tag: 'background-process',
    subTag: 'permissions',
    logMessage: 'Background service configured',
    level: LogLevel.INFO,
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    FlutterLogs.logInfo(
      'background_service',
      'onStart',
      'Starting background service',
    );

    WidgetsFlutterBinding.ensureInitialized();

    Timer.periodic(const Duration(minutes: 5), (timer) {
      FlutterLogs.logInfo(
        'background_service',
        'onStart',
        'Heartbeat at ${DateTime.now()}',
      );
    });

    bool hasPermission = false;
    int attempts = 0;
    const maxAttempts = 30;

    while (!hasPermission && attempts < maxAttempts) {
      hasPermission = await Permission.sms.status == PermissionStatus.granted;
      attempts++;

      if (!hasPermission) {
        await Future.delayed(const Duration(seconds: 10));
      }
    }

    if (!hasPermission) {
      service.stopSelf();
      return;
    }

    FlutterLogs.logInfo(
      'background_service',
      'onStart',
      'Listening for SMS messages....',
    );
    final plugin = Readsms();
    plugin.read();

    plugin.smsStream.listen(
      (event) async {
        try {
          FlutterLogs.logInfo(
            'background_service',
            'smsStream.listen',
            'SMS received: ${event.body}',
          );

          final response = await sendSmsMessage(event.body);
          if (response == null) {
            FlutterLogs.logError(
              'background_service',
              'smsStream.listen',
              'Failed to get response from SMS API',
            );
            return;
          }

          if (response['status'] == 'skipped') {
            return;
          }

          if (response['status'] == 'error') {
            final errorMessage = response['message'] ?? 'Error processing SMS';
            FlutterLogs.logError(
              'background_service',
              'smsStream.listen',
              'SMS API error: $errorMessage',
            );
            return;
          }

          if (response['status'] == 'success') {
            final String message = response['message'] ?? '';
            showNotification(message);
            if (kDebugMode) {
              print('SMS processed successfully: $message');
            }
          } else {
            final unknownStatus =
                'Unknown response status: ${response['status']}';

            if (kDebugMode) {
              print(unknownStatus);
            }
          }
        } catch (e) {
          print(e);
        }
      },
      onError: (error) {
        final errorMsg = 'SMS stream error: $error';
        if (kDebugMode) {
          print(errorMsg);
        }
      },
    );
    FlutterLogs.logThis(
      tag: 'background-process',
      subTag: 'service-start',
      logMessage: 'Background service fully initialized and listening for SMS',
      level: LogLevel.INFO,
    );
    if (kDebugMode) {
      print('Background service fully initialized and listening for SMS');
    }
  } catch (e) {
    final errorMsg = 'Critical error in background service: $e';
    if (kDebugMode) {
      print(errorMsg);
    }
    service.stopSelf();
  }
}

Future<void> showNotification(String message) async {
  try {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('icon');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'sms-agent-notifications',
          'SMS Agent Notifications',
          channelDescription: 'Notifications for SMS expense tracking',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message,
      "",
      notificationDetails,
    );
  } catch (e) {
    FlutterLogs.logThis(
      tag: 'notification',
      subTag: 'error',
      logMessage: 'Error showing notification: $e',
      level: LogLevel.ERROR,
    );
    if (kDebugMode) {
      print('Error showing notification: $e');
    }
  }
}

Future<Map<String, dynamic>?> sendSmsMessage(String message) async {
  const maxRetries = 3;
  const retryDelay = Duration(seconds: 2);

  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      final url = Uri.parse('${AppConstants.agentBaseUrl}/sms');
      final headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'PaisaApp/1.0',
      };

      final body = json.encode({
        'messages': [
          {'role': 'user', 'content': message},
        ],
      });

      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout after 30 seconds');
            },
          );

      if (response.statusCode == 200) {
        final decodedResponse =
            json.decode(response.body) as Map<String, dynamic>;
        if (kDebugMode) {
          print('SMS API response: ${response.statusCode}');
        }
        return decodedResponse;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending SMS message (attempt $attempt/$maxRetries): $e');
      }

      if (attempt == maxRetries) {
        // Last attempt failed
        return {
          'status': 'error',
          'message': 'Failed to send SMS after $maxRetries attempts: $e',
        };
      }

      // Wait before retrying
      await Future.delayed(retryDelay);
    }
  }

  return null;
}

Future<Map<String, bool>> requestAllPermissions() async {
  final permissions = [
    Permission.sms,
    Permission.notification,
    Permission.ignoreBatteryOptimizations,
  ];

  final Map<String, bool> results = {};

  for (final permission in permissions) {
    final status = await permission.request();
    results[permission.toString()] = status == PermissionStatus.granted;
  }

  // Show warning about battery optimization if not disabled
  if (!results[Permission.ignoreBatteryOptimizations.toString()]!) {
    showNotification(
      'Warning: Battery optimization not disabled. Background service may be killed by the system.',
    );
  }

  return results;
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  if (kDebugMode) {
    print('iOS background service handler called');
  }

  return true;
}
