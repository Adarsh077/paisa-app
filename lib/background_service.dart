import 'dart:convert';
import 'dart:ui';

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

void stopBackgroundService() {
  final service = FlutterBackgroundService();
  service.invoke("stop");
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
      isForegroundMode: false,
      autoStartOnBoot: true,
    ),
  );
}

Future<void> _showNotification(String message) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
        'sms-agent',
        'SMS Agent',
        channelDescription: 'SMS expenses records',
        importance: Importance.max,
        priority: Priority.high,
      );
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );
  await flutterLocalNotificationsPlugin.show(
    0,
    message,
    '',
    notificationDetails,
  );
}

/// Sends a message to the SMS API and returns the response
Future<Map<String, dynamic>?> sendSmsMessage(String message) async {
  try {
    final url = Uri.parse('${AppConstants.agentBaseUrl}/sms');
    final headers = {'Content-Type': 'application/json'};

    final body = json.encode({
      'messages': [
        {'role': 'user', 'content': message},
      ],
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to send SMS message. Status code: ${response.statusCode}',
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error sending SMS message: $e');
    }
    return null;
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    bool hasPermission = false;
    while (!hasPermission) {
      await Future.delayed(const Duration(seconds: 10));
      hasPermission = await Permission.sms.status == PermissionStatus.granted;
    }

    final plugin = Readsms();
    plugin.read();
    plugin.smsStream.listen((event) async {
      print('Received SMS: ${event.body}');
      final response = await sendSmsMessage(event.body);
      if (response == null) return;
      if (response['status'] == 'skipped') return;
      if (response['status'] == 'error') {
        _showNotification(response['message'] ?? 'Error processing SMS');
        return;
      }

      if (response['status'] == 'success') {
        final String message = response['message'] ?? '';
        _showNotification(message);
      } else {
        _showNotification('Unknown response status: ${response['status']}');
      }
    });
  } catch (e) {
    debugPrint('Error in background service: $e');
  }
}
