// import 'dart:async';
// import 'dart:io';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_logs/flutter_logs.dart';
// import 'package:device_info_plus/device_info_plus.dart';

// /// Enum representing the different states of the background service
// enum ServiceStatus { running, stopped, permissionDenied, starting, error }

// /// Data model representing the current status of the background service
// class BackgroundServiceStatus {
//   final bool isRunning;
//   final bool hasPermissions;
//   final DateTime lastChecked;
//   final String? errorMessage;
//   final ServiceStatus status;

//   const BackgroundServiceStatus({
//     required this.isRunning,
//     required this.hasPermissions,
//     required this.lastChecked,
//     this.errorMessage,
//     required this.status,
//   });

//   /// Returns true if the service is healthy (running and has permissions)
//   bool get isHealthy => isRunning && hasPermissions;

//   /// Creates a copy of this status with updated values
//   BackgroundServiceStatus copyWith({
//     bool? isRunning,
//     bool? hasPermissions,
//     DateTime? lastChecked,
//     String? errorMessage,
//     ServiceStatus? status,
//   }) {
//     return BackgroundServiceStatus(
//       isRunning: isRunning ?? this.isRunning,
//       hasPermissions: hasPermissions ?? this.hasPermissions,
//       lastChecked: lastChecked ?? this.lastChecked,
//       errorMessage: errorMessage ?? this.errorMessage,
//       status: status ?? this.status,
//     );
//   }

//   @override
//   String toString() {
//     return 'BackgroundServiceStatus(isRunning: $isRunning, hasPermissions: $hasPermissions, status: $status, lastChecked: $lastChecked, errorMessage: $errorMessage)';
//   }
// }

// /// Utility class for managing background service status and operations
// class BackgroundServiceManager {
//   static const String _logTag = 'BackgroundServiceManager';
//   static const int _maxRetryAttempts = 3;
//   static const Duration _retryDelay = Duration(seconds: 1);

//   /// Checks if the background service is currently running
//   static Future<bool> isServiceRunning() async {
//     try {
//       FlutterLogs.logInfo(
//         _logTag,
//         'isServiceRunning',
//         'Checking if background service is running',
//       );

//       final service = FlutterBackgroundService();
//       final isRunning = await service.isRunning();

//       FlutterLogs.logInfo(
//         _logTag,
//         'isServiceRunning',
//         'Background service running status: $isRunning',
//       );

//       return isRunning;
//     } catch (e) {
//       FlutterLogs.logError(
//         _logTag,
//         'isServiceRunning',
//         'Error checking service status: $e',
//       );
//       return false;
//     }
//   }

//   /// Checks if the app has all required permissions for the background service
//   static Future<bool> hasRequiredPermissions() async {
//     try {
//       FlutterLogs.logInfo(
//         _logTag,
//         'hasRequiredPermissions',
//         'Checking required permissions',
//       );

//       // Check SMS permission (primary requirement)
//       final smsPermission = await Permission.sms.status;
//       final hasSmsPermission = smsPermission == PermissionStatus.granted;

//       // Check notification permission
//       final notificationPermission = await Permission.notification.status;
//       final hasNotificationPermission =
//           notificationPermission == PermissionStatus.granted;

//       // Battery optimization is optional but recommended
//       final batteryOptimization =
//           await Permission.ignoreBatteryOptimizations.status;
//       final hasBatteryOptimization =
//           batteryOptimization == PermissionStatus.granted;

//       final hasAllRequired = hasSmsPermission && hasNotificationPermission;

//       FlutterLogs.logInfo(
//         _logTag,
//         'hasRequiredPermissions',
//         'Permissions - SMS: $hasSmsPermission, Notification: $hasNotificationPermission, Battery: $hasBatteryOptimization, All Required: $hasAllRequired',
//       );

//       return hasAllRequired;
//     } catch (e) {
//       FlutterLogs.logError(
//         _logTag,
//         'hasRequiredPermissions',
//         'Error checking permissions: $e',
//       );
//       return false;
//     }
//   }

//   /// Gets the detailed status of the background service
//   static Future<BackgroundServiceStatus> getServiceStatus() async {
//     try {
//       FlutterLogs.logInfo(
//         _logTag,
//         'getServiceStatus',
//         'Getting detailed service status',
//       );

//       final isRunning = await isServiceRunning();
//       final hasPermissions = await hasRequiredPermissions();
//       final now = DateTime.now();

//       ServiceStatus status;
//       String? errorMessage;

//       if (!hasPermissions) {
//         status = ServiceStatus.permissionDenied;
//         errorMessage = 'Required permissions not granted';
//       } else if (isRunning) {
//         status = ServiceStatus.running;
//       } else {
//         status = ServiceStatus.stopped;
//       }

//       final serviceStatus = BackgroundServiceStatus(
//         isRunning: isRunning,
//         hasPermissions: hasPermissions,
//         lastChecked: now,
//         errorMessage: errorMessage,
//         status: status,
//       );

//       FlutterLogs.logInfo(
//         _logTag,
//         'getServiceStatus',
//         'Service status: $serviceStatus',
//       );

//       return serviceStatus;
//     } catch (e) {
//       FlutterLogs.logError(
//         _logTag,
//         'getServiceStatus',
//         'Error getting service status: $e',
//       );

//       return BackgroundServiceStatus(
//         isRunning: false,
//         hasPermissions: false,
//         lastChecked: DateTime.now(),
//         errorMessage: 'Error checking service status: $e',
//         status: ServiceStatus.error,
//       );
//     }
//   }

//   /// Starts the background service with comprehensive error handling and verification
//   static Future<bool> startService() async {
//     try {
//       FlutterLogs.logInfo(
//         _logTag,
//         'startService',
//         'Attempting to start background service',
//       );

//       // Check permissions first
//       final hasPermissions = await hasRequiredPermissions();
//       if (!hasPermissions) {
//         FlutterLogs.logError(
//           _logTag,
//           'startService',
//           'Cannot start service: missing required permissions',
//         );
//         return false;
//       }

//       final service = FlutterBackgroundService();

//       // Check if already running
//       final isAlreadyRunning = await service.isRunning();
//       if (isAlreadyRunning) {
//         FlutterLogs.logInfo(
//           _logTag,
//           'startService',
//           'Service is already running',
//         );
//         return true;
//       }

//       // Start the service
//       FlutterLogs.logInfo(
//         _logTag,
//         'startService',
//         'Initiating service start...',
//       );

//       await service.startService();

//       // Wait and verify with multiple checks to ensure service is properly started
//       const maxAttempts = 10;
//       const checkInterval = Duration(milliseconds: 500);

//       for (int attempt = 1; attempt <= maxAttempts; attempt++) {
//         await Future.delayed(checkInterval);

//         final isNowRunning = await service.isRunning();

//         FlutterLogs.logInfo(
//           _logTag,
//           'startService',
//           'Service status check $attempt/$maxAttempts: $isNowRunning',
//         );

//         if (isNowRunning) {
//           FlutterLogs.logInfo(
//             _logTag,
//             'startService',
//             'Service started successfully after ${attempt * checkInterval.inMilliseconds}ms',
//           );
//           return true;
//         }
//       }

//       FlutterLogs.logError(
//         _logTag,
//         'startService',
//         'Service failed to start after ${maxAttempts * checkInterval.inMilliseconds}ms',
//       );

//       return false;
//     } catch (e) {
//       FlutterLogs.logError(
//         _logTag,
//         'startService',
//         'Error starting service: $e',
//       );
//       return false;
//     }
//   }

//   /// Stops the background service
//   static Future<void> stopService() async {
//     try {
//       FlutterLogs.logInfo(
//         _logTag,
//         'stopService',
//         'Attempting to stop background service',
//       );

//       final service = FlutterBackgroundService();

//       // Check if running first
//       final isRunning = await service.isRunning();
//       if (!isRunning) {
//         FlutterLogs.logInfo(_logTag, 'stopService', 'Service is not running');
//         return;
//       }

//       // Stop the service
//       service.invoke('stopService');

//       FlutterLogs.logInfo(_logTag, 'stopService', 'Service stop command sent');
//     } catch (e) {
//       FlutterLogs.logError(
//         _logTag,
//         'stopService',
//         'Error stopping service: $e',
//       );
//     }
//   }

//   /// Restarts the background service (stop then start with verification)
//   static Future<bool> restartService() async {
//     try {
//       FlutterLogs.logInfo(
//         _logTag,
//         'restartService',
//         'Attempting to restart background service',
//       );

//       // First, stop the service if it's running
//       await stopService();

//       // Wait a moment for the service to fully stop
//       await Future.delayed(const Duration(milliseconds: 1000));

//       // Verify service is stopped
//       final service = FlutterBackgroundService();
//       final isStillRunning = await service.isRunning();

//       if (isStillRunning) {
//         FlutterLogs.logWarn(
//           _logTag,
//           'restartService',
//           'Service is still running after stop command, proceeding with start anyway',
//         );
//       }

//       // Now start the service
//       final startSuccess = await startService();

//       FlutterLogs.logInfo(
//         _logTag,
//         'restartService',
//         'Service restart result: $startSuccess',
//       );

//       return startSuccess;
//     } catch (e) {
//       FlutterLogs.logError(
//         _logTag,
//         'restartService',
//         'Error restarting service: $e',
//       );
//       return false;
//     }
//   }

//   /// Performs comprehensive system diagnostics for troubleshooting
//   static Future<Map<String, dynamic>> performSystemDiagnostics() async {
//     final diagnostics = <String, dynamic>{};

//     try {
//       FlutterLogs.logInfo(
//         _logTag,
//         'performSystemDiagnostics',
//         'Performing comprehensive system diagnostics',
//       );

//       // Basic service status
//       diagnostics['serviceRunning'] = await isServiceRunning();
//       diagnostics['hasPermissions'] = await hasRequiredPermissions();
//       diagnostics['timestamp'] = DateTime.now().toIso8601String();

//       // Detailed permission status
//       final permissionDetails = <String, String>{};
//       try {
//         permissionDetails['sms'] = (await Permission.sms.status).toString();
//         permissionDetails['notification'] =
//             (await Permission.notification.status).toString();
//         permissionDetails['batteryOptimization'] =
//             (await Permission.ignoreBatteryOptimizations.status).toString();
//         permissionDetails['phone'] = (await Permission.phone.status).toString();
//       } catch (e) {
//         permissionDetails['error'] = 'Failed to check permissions: $e';
//       }
//       diagnostics['permissions'] = permissionDetails;

//       // Device information
//       final deviceInfo = <String, dynamic>{};
//       try {
//         if (Platform.isAndroid) {
//           final androidInfo = await DeviceInfoPlugin().androidInfo;
//           deviceInfo['platform'] = 'Android';
//           deviceInfo['version'] = androidInfo.version.release;
//           deviceInfo['sdkInt'] = androidInfo.version.sdkInt;
//           deviceInfo['manufacturer'] = androidInfo.manufacturer;
//           deviceInfo['model'] = androidInfo.model;
//           deviceInfo['brand'] = androidInfo.brand;

//           // Check for known problematic manufacturers/versions
//           final problematicBrands = [
//             'xiaomi',
//             'huawei',
//             'oppo',
//             'vivo',
//             'oneplus',
//           ];
//           final isProblematicBrand = problematicBrands.any(
//             (brand) => androidInfo.brand.toLowerCase().contains(brand),
//           );
//           deviceInfo['isProblematicBrand'] = isProblematicBrand;

//           if (isProblematicBrand) {
//             deviceInfo['batteryOptimizationNote'] =
//                 'This device brand may require manual battery optimization settings';
//           }
//         } else if (Platform.isIOS) {
//           final iosInfo = await DeviceInfoPlugin().iosInfo;
//           deviceInfo['platform'] = 'iOS';
//           deviceInfo['version'] = iosInfo.systemVersion;
//           deviceInfo['model'] = iosInfo.model;
//           deviceInfo['name'] = iosInfo.name;
//         }
//       } catch (e) {
//         deviceInfo['error'] = 'Failed to get device info: $e';
//       }
//       diagnostics['device'] = deviceInfo;

//       // System resource checks
//       final systemChecks = <String, dynamic>{};
//       try {
//         // Check available memory (basic check)
//         systemChecks['timestamp'] = DateTime.now().millisecondsSinceEpoch;

//         // Check if we can create timers (basic system health)
//         final testTimer = Timer(const Duration(milliseconds: 1), () {});
//         testTimer.cancel();
//         systemChecks['timerCreation'] = 'OK';

//         // Check if we can access FlutterBackgroundService
//         try {
//           FlutterBackgroundService();
//           systemChecks['serviceAccess'] = 'OK';
//         } catch (e) {
//           systemChecks['serviceAccess'] = 'Failed: $e';
//         }
//       } catch (e) {
//         systemChecks['error'] = 'System check failed: $e';
//       }
//       diagnostics['system'] = systemChecks;

//       FlutterLogs.logInfo(
//         _logTag,
//         'performSystemDiagnostics',
//         'System diagnostics completed: ${diagnostics.keys.join(', ')}',
//       );

//       return diagnostics;
//     } catch (e) {
//       FlutterLogs.logError(
//         _logTag,
//         'performSystemDiagnostics',
//         'Error performing system diagnostics: $e',
//       );

//       return {
//         'error': 'Failed to perform diagnostics: $e',
//         'timestamp': DateTime.now().toIso8601String(),
//       };
//     }
//   }

//   /// Attempts to recover from common service issues
//   static Future<bool> attemptServiceRecovery() async {
//     try {
//       FlutterLogs.logInfo(
//         _logTag,
//         'attemptServiceRecovery',
//         'Attempting service recovery',
//       );

//       // Step 1: Perform diagnostics to understand the issue
//       final diagnostics = await performSystemDiagnostics();

//       FlutterLogs.logInfo(
//         _logTag,
//         'attemptServiceRecovery',
//         'Diagnostics: $diagnostics',
//       );

//       // Step 2: Check if it's a permission issue
//       if (diagnostics['hasPermissions'] == false) {
//         FlutterLogs.logError(
//           _logTag,
//           'attemptServiceRecovery',
//           'Recovery failed: Missing required permissions',
//         );
//         return false;
//       }

//       // Step 3: Try multiple restart attempts with increasing delays
//       for (int attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
//         FlutterLogs.logInfo(
//           _logTag,
//           'attemptServiceRecovery',
//           'Recovery attempt $attempt/$_maxRetryAttempts',
//         );

//         // Force stop any existing service
//         try {
//           final service = FlutterBackgroundService();
//           service.invoke('stopService');
//           await Future.delayed(Duration(milliseconds: 500 * attempt));
//         } catch (e) {
//           FlutterLogs.logWarn(
//             _logTag,
//             'attemptServiceRecovery',
//             'Error during force stop: $e',
//           );
//         }

//         // Attempt to start service
//         final success = await startService();
//         if (success) {
//           FlutterLogs.logInfo(
//             _logTag,
//             'attemptServiceRecovery',
//             'Service recovery successful on attempt $attempt',
//           );
//           return true;
//         }

//         // Wait before next attempt with exponential backoff
//         if (attempt < _maxRetryAttempts) {
//           final delay = _retryDelay * attempt;
//           FlutterLogs.logInfo(
//             _logTag,
//             'attemptServiceRecovery',
//             'Waiting ${delay.inSeconds}s before next attempt',
//           );
//           await Future.delayed(delay);
//         }
//       }

//       FlutterLogs.logError(
//         _logTag,
//         'attemptServiceRecovery',
//         'Service recovery failed after $_maxRetryAttempts attempts',
//       );

//       return false;
//     } catch (e) {
//       FlutterLogs.logError(
//         _logTag,
//         'attemptServiceRecovery',
//         'Error during service recovery: $e',
//       );
//       return false;
//     }
//   }

//   /// Gets user-friendly error message based on service status and diagnostics
//   static Future<String> getUserFriendlyErrorMessage(
//     ServiceStatus status,
//   ) async {
//     try {
//       switch (status) {
//         case ServiceStatus.permissionDenied:
//           return 'SMS and notification permissions are required. Please grant permissions in Settings.';

//         case ServiceStatus.error:
//           // Perform diagnostics to provide more specific error message
//           final diagnostics = await performSystemDiagnostics();

//           if (diagnostics['device'] != null) {
//             final device = diagnostics['device'] as Map<String, dynamic>;
//             if (device['isProblematicBrand'] == true) {
//               return 'Your device may require additional battery optimization settings. Please check Settings > Battery > App Battery Optimization.';
//             }
//           }

//           return 'Service encountered an error. Please try restarting or check app permissions.';

//         case ServiceStatus.stopped:
//           return 'Background service is not running. Tap to start SMS monitoring.';

//         case ServiceStatus.starting:
//           return 'Starting background service...';

//         case ServiceStatus.running:
//           return 'Background service is running and monitoring SMS.';
//       }
//     } catch (e) {
//       FlutterLogs.logError(
//         _logTag,
//         'getUserFriendlyErrorMessage',
//         'Error getting user-friendly message: $e',
//       );
//     }

//     return 'Unknown service status. Please try restarting the service.';
//   }

//   /// Validates service health with comprehensive checks
//   static Future<bool> validateServiceHealth() async {
//     try {
//       FlutterLogs.logInfo(
//         _logTag,
//         'validateServiceHealth',
//         'Validating service health',
//       );

//       // Basic checks
//       final isRunning = await isServiceRunning();
//       final hasPermissions = await hasRequiredPermissions();

//       if (!isRunning || !hasPermissions) {
//         FlutterLogs.logWarn(
//           _logTag,
//           'validateServiceHealth',
//           'Basic health check failed - Running: $isRunning, Permissions: $hasPermissions',
//         );
//         return false;
//       }

//       // Advanced health checks
//       try {
//         final service = FlutterBackgroundService();

//         // Try to communicate with the service
//         service.invoke('healthCheck');

//         // Wait a moment and check if service is still running
//         await Future.delayed(const Duration(milliseconds: 500));
//         final stillRunning = await service.isRunning();

//         if (!stillRunning) {
//           FlutterLogs.logError(
//             _logTag,
//             'validateServiceHealth',
//             'Service stopped responding after health check',
//           );
//           return false;
//         }

//         FlutterLogs.logInfo(
//           _logTag,
//           'validateServiceHealth',
//           'Service health validation passed',
//         );

//         return true;
//       } catch (e) {
//         FlutterLogs.logError(
//           _logTag,
//           'validateServiceHealth',
//           'Advanced health check failed: $e',
//         );
//         return false;
//       }
//     } catch (e) {
//       FlutterLogs.logError(
//         _logTag,
//         'validateServiceHealth',
//         'Error validating service health: $e',
//       );
//       return false;
//     }
//   }
// }
