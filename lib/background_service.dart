import 'dart:convert';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:readsms/readsms.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';

void startBackgroundService() {
  final service = FlutterBackgroundService();
  service.startService();
}

Future<void> initializeService() async {
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

  if (kDebugMode) {
    showNotification('Background Service initialized (background-only mode)');
    print(
      'Warning: Background-only mode may be limited by Android battery optimization',
    );
    print(
      'For best reliability, consider asking users to disable battery optimization',
    );
  }
}

Future<void> showNotification(String message) async {
  try {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'sms-agent-notifications',
          'SMS Agent Notifications',
          channelDescription: 'Notifications for SMS expense tracking',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          enableLights: true,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'SMS Agent',
      message,
      notificationDetails,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error showing notification: $e');
    }
  }
}

/// Sends a message to the SMS API and returns the response
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

      if (kDebugMode) {
        print('Sending SMS to API (attempt $attempt/$maxRetries)');
      }

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

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  if (kDebugMode) {
    print('iOS background service handler called');
  }

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Send periodic heartbeat to prevent service from being killed
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (kDebugMode) {
        print('Background service heartbeat: ${DateTime.now()}');
      }
    });

    if (kDebugMode) {
      print('Background service started (background-only mode)');
    }

    // Wait for SMS permission with timeout
    bool hasPermission = false;
    int attempts = 0;
    const maxAttempts = 30; // 5 minutes maximum wait

    while (!hasPermission && attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 10));
      hasPermission = await Permission.sms.status == PermissionStatus.granted;
      attempts++;

      if (kDebugMode) {
        print(
          'Checking SMS permission, attempt: $attempts, granted: $hasPermission',
        );
      }
    }

    if (!hasPermission) {
      showNotification(
        'SMS permission not granted. Background service cannot function.',
      );
      service.stopSelf();
      return;
    }

    // Initialize SMS reading
    final plugin = Readsms();
    plugin.read();

    // Listen to SMS stream
    plugin.smsStream.listen(
      (event) async {
        try {
          if (kDebugMode) {
            print('SMS received: ${event.body.substring(0, 50)}...');
          }

          final response = await sendSmsMessage(event.body);
          if (response == null) {
            if (kDebugMode) {
              print('No response from SMS API');
            }
            return;
          }

          if (response['status'] == 'skipped') {
            if (kDebugMode) {
              print('SMS skipped by API');
            }
            return;
          }

          if (response['status'] == 'error') {
            final errorMessage = response['message'] ?? 'Error processing SMS';
            showNotification(errorMessage);
            if (kDebugMode) {
              print('SMS API error: $errorMessage');
            }
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
            showNotification(unknownStatus);
            if (kDebugMode) {
              print(unknownStatus);
            }
          }
        } catch (e) {
          final errorMsg = 'Error processing SMS: $e';
          if (kDebugMode) {
            print(errorMsg);
          }
          showNotification(errorMsg);
        }
      },
      onError: (error) {
        final errorMsg = 'SMS stream error: $error';
        if (kDebugMode) {
          print(errorMsg);
        }
        showNotification(errorMsg);
      },
    );

    if (kDebugMode) {
      print('Background service fully initialized and listening for SMS');
    }
  } catch (e) {
    final errorMsg = 'Critical error in background service: $e';
    if (kDebugMode) {
      print(errorMsg);
    }
    showNotification(errorMsg);
    service.stopSelf();
  }
}

/// Check if the background service is running
Future<bool> isBackgroundServiceRunning() async {
  final service = FlutterBackgroundService();
  return await service.isRunning();
}

/// Get background service status information
Future<Map<String, dynamic>> getBackgroundServiceStatus() async {
  final service = FlutterBackgroundService();
  final isRunning = await service.isRunning();
  final hasSmsPermission =
      await Permission.sms.status == PermissionStatus.granted;
  final hasNotificationPermission =
      await Permission.notification.status == PermissionStatus.granted;

  return {
    'isRunning': isRunning,
    'hasSmsPermission': hasSmsPermission,
    'hasNotificationPermission': hasNotificationPermission,
    'timestamp': DateTime.now().toIso8601String(),
  };
}

/// Request all necessary permissions for the background service
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

/// Restart the background service
Future<void> restartBackgroundService() async {
  final service = FlutterBackgroundService();

  // Stop the service if it's running
  if (await service.isRunning()) {
    service.invoke("stop");
    await Future.delayed(const Duration(seconds: 2));
  }

  // Start the service
  service.startService();

  if (kDebugMode) {
    showNotification('Background service restarted');
  }
}

/// Check if device has battery optimization restrictions
Future<bool> isBatteryOptimizationDisabled() async {
  return await Permission.ignoreBatteryOptimizations.status ==
      PermissionStatus.granted;
}

/// Request to disable battery optimization for better background execution
Future<bool> requestDisableBatteryOptimization() async {
  final status = await Permission.ignoreBatteryOptimizations.request();
  return status == PermissionStatus.granted;
}
