import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';
import '../services/background_service_manager.dart';

/// Provider for managing background service status monitoring and operations
class BackgroundServiceStatusProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  static const String _logTag = 'BackgroundServiceStatusProvider';

  // Optimized polling intervals for better battery life
  static const Duration _normalPollingInterval = Duration(seconds: 3);
  static const Duration _fastPollingInterval = Duration(seconds: 1);
  static const Duration _slowPollingInterval = Duration(seconds: 10);
  static const Duration _backgroundPollingInterval = Duration(seconds: 30);

  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  // Private state variables
  BackgroundServiceStatus _currentStatus = BackgroundServiceStatus(
    isRunning: false,
    hasPermissions: false,
    lastChecked: DateTime.now(),
    status: ServiceStatus.stopped,
  );
  bool _isLoading = false;
  bool _isMonitoring = false;
  bool _isAppInBackground = false;
  bool _isAppPaused = false;
  Timer? _statusCheckTimer;
  Timer? _debounceTimer;
  int _consecutiveErrors = 0;
  DateTime? _lastErrorTime;
  DateTime? _lastSuccessfulCheck;

  // Performance optimization variables
  bool _isDisposed = false;
  int _notificationCount = 0;
  DateTime? _lastNotificationTime;

  // Public getters
  BackgroundServiceStatus get currentStatus => _currentStatus;
  bool get isServiceRunning => _currentStatus.isRunning;
  bool get hasPermissions => _currentStatus.hasPermissions;
  bool get isLoading => _isLoading;
  bool get isMonitoring => _isMonitoring;
  bool get isHealthy => _currentStatus.isHealthy;
  ServiceStatus get serviceStatus => _currentStatus.status;
  String? get errorMessage => _currentStatus.errorMessage;

  /// Starts monitoring the background service status with timer-based polling
  Future<void> startStatusMonitoring() async {
    if (_isMonitoring) {
      FlutterLogs.logInfo(
        _logTag,
        'startStatusMonitoring',
        'Status monitoring is already active',
      );
      return;
    }

    FlutterLogs.logInfo(
      _logTag,
      'startStatusMonitoring',
      'Starting background service status monitoring',
    );

    _isMonitoring = true;
    _consecutiveErrors = 0;
    _lastErrorTime = null;

    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Perform initial status check
    await checkServiceStatus();

    // Start periodic status checking with adaptive polling
    _startAdaptivePolling();

    notifyListeners();
  }

  /// Starts adaptive polling based on app state and error conditions
  void _startAdaptivePolling() {
    if (_isDisposed) return;

    Duration pollingInterval = _determineOptimalPollingInterval();

    FlutterLogs.logInfo(
      _logTag,
      '_startAdaptivePolling',
      'Starting adaptive polling with interval: ${pollingInterval.inSeconds}s',
    );

    _statusCheckTimer?.cancel(); // Ensure no duplicate timers
    _statusCheckTimer = Timer.periodic(pollingInterval, (_) async {
      if (_isDisposed || !_isMonitoring) return;

      // Skip polling if app is paused or in background for too long
      if (_isAppPaused ||
          (_isAppInBackground && _shouldSkipBackgroundPolling())) {
        return;
      }

      await _checkServiceStatusWithRetry();
    });
  }

  /// Determines the optimal polling interval based on current conditions
  Duration _determineOptimalPollingInterval() {
    // Fast polling conditions
    if (_consecutiveErrors > 0) {
      return _fastPollingInterval;
    }

    // Recent app resume - use fast polling for first few checks
    if (_lastSuccessfulCheck != null &&
        DateTime.now().difference(_lastSuccessfulCheck!).inSeconds < 30) {
      return _fastPollingInterval;
    }

    // Recent errors - use fast polling
    if (_lastErrorTime != null &&
        DateTime.now().difference(_lastErrorTime!).inMinutes < 5) {
      return _fastPollingInterval;
    }

    // App in background - use slow polling to save battery
    if (_isAppInBackground && !_isAppPaused) {
      return _backgroundPollingInterval;
    }

    // Service is healthy and stable - use slower polling
    if (_currentStatus.isHealthy && _consecutiveErrors == 0) {
      final timeSinceLastCheck =
          _lastSuccessfulCheck != null
              ? DateTime.now().difference(_lastSuccessfulCheck!)
              : Duration.zero;

      if (timeSinceLastCheck.inMinutes > 10) {
        return _slowPollingInterval;
      }
    }

    // Default normal polling
    return _normalPollingInterval;
  }

  /// Determines if background polling should be skipped to save battery
  bool _shouldSkipBackgroundPolling() {
    // Skip if app has been in background for more than 5 minutes
    // and service was last known to be healthy
    return _currentStatus.isHealthy &&
        _lastSuccessfulCheck != null &&
        DateTime.now().difference(_lastSuccessfulCheck!).inMinutes > 5;
  }

  /// Stops monitoring the background service status
  Future<void> stopStatusMonitoring() async {
    if (!_isMonitoring) {
      FlutterLogs.logInfo(
        _logTag,
        'stopStatusMonitoring',
        'Status monitoring is not active',
      );
      return;
    }

    FlutterLogs.logInfo(
      _logTag,
      'stopStatusMonitoring',
      'Stopping background service status monitoring',
    );

    _isMonitoring = false;
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;

    // Unregister from app lifecycle events
    WidgetsBinding.instance.removeObserver(this);

    notifyListeners();
  }

  /// App lifecycle state change handler
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    super.didChangeAppLifecycleState(state);

    FlutterLogs.logInfo(
      _logTag,
      'didChangeAppLifecycleState',
      'App lifecycle state changed to: $state',
    );

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  /// Handles app becoming inactive (temporary state)
  void _handleAppInactive() {
    if (_isDisposed) return;

    FlutterLogs.logInfo(
      _logTag,
      '_handleAppInactive',
      'App became inactive, maintaining current monitoring state',
    );

    // Don't change monitoring behavior for inactive state
    // as this is often temporary (e.g., during phone calls)
  }

  /// Handles app being hidden (iOS specific)
  void _handleAppHidden() {
    if (_isDisposed) return;

    FlutterLogs.logInfo(
      _logTag,
      '_handleAppHidden',
      'App hidden, switching to background mode',
    );

    _isAppInBackground = true;

    if (_isMonitoring) {
      _statusCheckTimer?.cancel();
      _startAdaptivePolling();
    }
  }

  /// Handles app being detached (about to be terminated)
  void _handleAppDetached() {
    if (_isDisposed) return;

    FlutterLogs.logInfo(
      _logTag,
      '_handleAppDetached',
      'App detached, preparing for termination',
    );

    // Minimize resource usage when app is about to be terminated
    _isAppInBackground = true;
    _isAppPaused = true;

    // Cancel timers to save resources
    _statusCheckTimer?.cancel();
    _debounceTimer?.cancel();
  }

  /// Handles app resuming from background
  void _handleAppResumed() {
    if (_isDisposed) return;

    FlutterLogs.logInfo(
      _logTag,
      '_handleAppResumed',
      'App resumed from background, refreshing service status',
    );

    _isAppInBackground = false;
    _isAppPaused = false;

    if (_isMonitoring) {
      // Immediately check service status when app resumes
      _debouncedStatusCheck();

      // Restart adaptive polling with optimized interval
      _statusCheckTimer?.cancel();
      _startAdaptivePolling();
    }
  }

  /// Handles app going to background/paused
  void _handleAppPaused() {
    if (_isDisposed) return;

    FlutterLogs.logInfo(
      _logTag,
      '_handleAppPaused',
      'App paused/backgrounded, optimizing monitoring for battery life',
    );

    _isAppInBackground = true;
    _isAppPaused = true;

    if (_isMonitoring) {
      // Switch to background-optimized polling
      _statusCheckTimer?.cancel();
      _startAdaptivePolling();
    }
  }

  /// Enhanced status checking with retry logic and error recovery
  Future<void> _checkServiceStatusWithRetry() async {
    try {
      await checkServiceStatus();

      // Reset error counter on successful check
      if (_consecutiveErrors > 0) {
        FlutterLogs.logInfo(
          _logTag,
          '_checkServiceStatusWithRetry',
          'Service status check recovered after $_consecutiveErrors consecutive errors',
        );
        _consecutiveErrors = 0;
        _lastErrorTime = null;

        // Switch back to normal polling interval
        _statusCheckTimer?.cancel();
        _startAdaptivePolling();
      }

      // Periodic memory optimization
      if (_notificationCount % 50 == 0) {
        _optimizeMemoryUsage();
      }
    } catch (e) {
      _consecutiveErrors++;
      _lastErrorTime = DateTime.now();

      FlutterLogs.logError(
        _logTag,
        '_checkServiceStatusWithRetry',
        'Service status check failed (attempt $_consecutiveErrors): $e',
      );

      // Implement exponential backoff for repeated failures
      if (_consecutiveErrors >= _maxRetryAttempts) {
        FlutterLogs.logError(
          _logTag,
          '_checkServiceStatusWithRetry',
          'Maximum retry attempts reached, implementing backoff',
        );

        // Update status to indicate persistent error
        _currentStatus = _currentStatus.copyWith(
          status: ServiceStatus.error,
          lastChecked: DateTime.now(),
          errorMessage:
              'Persistent error checking service status. Will retry automatically.',
        );

        _throttledNotifyListeners();

        // Implement exponential backoff
        await Future.delayed(_retryDelay * _consecutiveErrors);
      }
    }
  }

  /// Debounced status check to prevent excessive API calls
  void _debouncedStatusCheck() {
    if (_isDisposed) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (!_isDisposed && _isMonitoring) {
        checkServiceStatus();
      }
    });
  }

  /// Checks the current status of the background service
  Future<void> checkServiceStatus() async {
    if (_isDisposed) return;

    try {
      FlutterLogs.logInfo(
        _logTag,
        'checkServiceStatus',
        'Checking background service status',
      );

      final newStatus = await BackgroundServiceManager.getServiceStatus();
      _lastSuccessfulCheck = DateTime.now();

      // Only update and notify if status has changed to minimize UI updates
      if (_hasStatusChanged(newStatus)) {
        _currentStatus = newStatus;

        FlutterLogs.logInfo(
          _logTag,
          'checkServiceStatus',
          'Status updated: ${newStatus.status}, Running: ${newStatus.isRunning}, Permissions: ${newStatus.hasPermissions}',
        );

        _throttledNotifyListeners();
      }
    } catch (e) {
      FlutterLogs.logError(
        _logTag,
        'checkServiceStatus',
        'Error checking service status: $e',
      );

      // Update status to error state
      _currentStatus = BackgroundServiceStatus(
        isRunning: false,
        hasPermissions: false,
        lastChecked: DateTime.now(),
        errorMessage: 'Error checking service status: $e',
        status: ServiceStatus.error,
      );

      _throttledNotifyListeners();
      rethrow; // Re-throw for retry logic
    }
  }

  /// Throttled notification to prevent excessive UI updates
  void _throttledNotifyListeners() {
    if (_isDisposed) return;

    final now = DateTime.now();

    // Throttle notifications to max 2 per second to prevent UI performance issues
    if (_lastNotificationTime == null ||
        now.difference(_lastNotificationTime!).inMilliseconds > 500) {
      _lastNotificationTime = now;
      _notificationCount++;

      // Log excessive notifications for debugging
      if (_notificationCount > 100) {
        FlutterLogs.logWarn(
          _logTag,
          '_throttledNotifyListeners',
          'High notification count detected: $_notificationCount',
        );
        _notificationCount = 0; // Reset counter
      }

      notifyListeners();
    }
  }

  /// Starts the background service with loading state management and timeout handling
  Future<bool> startBackgroundService() async {
    if (_isLoading) {
      FlutterLogs.logInfo(
        _logTag,
        'startBackgroundService',
        'Service start operation already in progress',
      );
      return false;
    }

    FlutterLogs.logInfo(
      _logTag,
      'startBackgroundService',
      'Starting background service',
    );

    _isLoading = true;

    // Update status to starting
    _currentStatus = _currentStatus.copyWith(
      status: ServiceStatus.starting,
      lastChecked: DateTime.now(),
      errorMessage: null,
    );

    notifyListeners();

    try {
      // Add timeout handling for service start operation
      final success = await BackgroundServiceManager.startService().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          FlutterLogs.logError(
            _logTag,
            'startBackgroundService',
            'Service start operation timed out after 30 seconds',
          );
          throw TimeoutException(
            'Service start operation timed out',
            const Duration(seconds: 30),
          );
        },
      );

      if (success) {
        FlutterLogs.logInfo(
          _logTag,
          'startBackgroundService',
          'Background service started successfully',
        );

        // Wait a moment for service to fully initialize
        await Future.delayed(const Duration(milliseconds: 1500));

        // Check status to get updated state
        await checkServiceStatus();

        // Verify service is actually running and healthy
        if (!_currentStatus.isHealthy) {
          FlutterLogs.logError(
            _logTag,
            'startBackgroundService',
            'Service started but is not healthy: ${_currentStatus.errorMessage}',
          );

          _isLoading = false;
          _currentStatus = _currentStatus.copyWith(
            status: ServiceStatus.error,
            lastChecked: DateTime.now(),
            errorMessage:
                _currentStatus.errorMessage ??
                'Service started but is not healthy',
          );
          notifyListeners();
          return false;
        }
      } else {
        FlutterLogs.logError(
          _logTag,
          'startBackgroundService',
          'Failed to start background service',
        );

        // Update status to error with specific failure reason
        String errorMessage = 'Failed to start background service';

        // Check if it's a permission issue
        final hasPermissions =
            await BackgroundServiceManager.hasRequiredPermissions();
        if (!hasPermissions) {
          errorMessage = 'Missing required permissions (SMS, Notifications)';
          _currentStatus = _currentStatus.copyWith(
            status: ServiceStatus.permissionDenied,
            lastChecked: DateTime.now(),
            errorMessage: errorMessage,
          );
        } else {
          _currentStatus = _currentStatus.copyWith(
            status: ServiceStatus.error,
            lastChecked: DateTime.now(),
            errorMessage: errorMessage,
          );
        }
      }

      _isLoading = false;
      notifyListeners();

      return success;
    } on TimeoutException catch (e) {
      FlutterLogs.logError(
        _logTag,
        'startBackgroundService',
        'Service start timed out: $e',
      );

      _isLoading = false;
      _currentStatus = _currentStatus.copyWith(
        status: ServiceStatus.error,
        lastChecked: DateTime.now(),
        errorMessage: 'Service start operation timed out. Please try again.',
      );

      notifyListeners();
      return false;
    } catch (e) {
      FlutterLogs.logError(
        _logTag,
        'startBackgroundService',
        'Error starting background service: $e',
      );

      _isLoading = false;

      // Provide more specific error messages
      String errorMessage = 'Error starting service: $e';
      if (e.toString().contains('permission')) {
        errorMessage =
            'Permission denied. Please grant SMS and notification permissions.';
        _currentStatus = _currentStatus.copyWith(
          status: ServiceStatus.permissionDenied,
          lastChecked: DateTime.now(),
          errorMessage: errorMessage,
        );
      } else {
        _currentStatus = _currentStatus.copyWith(
          status: ServiceStatus.error,
          lastChecked: DateTime.now(),
          errorMessage: errorMessage,
        );
      }

      notifyListeners();
      return false;
    }
  }

  /// Stops the background service
  Future<void> stopBackgroundService() async {
    FlutterLogs.logInfo(
      _logTag,
      'stopBackgroundService',
      'Stopping background service',
    );

    try {
      await BackgroundServiceManager.stopService();

      // Wait a moment for service to fully stop
      await Future.delayed(const Duration(milliseconds: 500));

      // Check status to get updated state
      await checkServiceStatus();

      FlutterLogs.logInfo(
        _logTag,
        'stopBackgroundService',
        'Background service stopped',
      );
    } catch (e) {
      FlutterLogs.logError(
        _logTag,
        'stopBackgroundService',
        'Error stopping background service: $e',
      );

      _currentStatus = _currentStatus.copyWith(
        status: ServiceStatus.error,
        lastChecked: DateTime.now(),
        errorMessage: 'Error stopping service: $e',
      );

      notifyListeners();
    }
  }

  /// Restarts the background service with comprehensive error handling and timeout
  Future<bool> restartBackgroundService() async {
    if (_isLoading) {
      FlutterLogs.logInfo(
        _logTag,
        'restartBackgroundService',
        'Service restart operation already in progress',
      );
      return false;
    }

    FlutterLogs.logInfo(
      _logTag,
      'restartBackgroundService',
      'Restarting background service',
    );

    _isLoading = true;

    // Update status to starting
    _currentStatus = _currentStatus.copyWith(
      status: ServiceStatus.starting,
      lastChecked: DateTime.now(),
      errorMessage: null,
    );

    notifyListeners();

    try {
      // Add timeout handling for service restart operation
      final success = await BackgroundServiceManager.restartService().timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          FlutterLogs.logError(
            _logTag,
            'restartBackgroundService',
            'Service restart operation timed out after 45 seconds',
          );
          throw TimeoutException(
            'Service restart operation timed out',
            const Duration(seconds: 45),
          );
        },
      );

      if (success) {
        FlutterLogs.logInfo(
          _logTag,
          'restartBackgroundService',
          'Background service restarted successfully',
        );

        // Wait a moment for service to fully initialize
        await Future.delayed(const Duration(milliseconds: 2000));

        // Check status to get updated state
        await checkServiceStatus();

        // Verify service is actually running and healthy
        if (!_currentStatus.isHealthy) {
          FlutterLogs.logError(
            _logTag,
            'restartBackgroundService',
            'Service restarted but is not healthy: ${_currentStatus.errorMessage}',
          );

          _isLoading = false;
          _currentStatus = _currentStatus.copyWith(
            status: ServiceStatus.error,
            lastChecked: DateTime.now(),
            errorMessage:
                _currentStatus.errorMessage ??
                'Service restarted but is not healthy',
          );
          notifyListeners();
          return false;
        }
      } else {
        FlutterLogs.logError(
          _logTag,
          'restartBackgroundService',
          'Failed to restart background service',
        );

        // Update status to error with specific failure reason
        String errorMessage = 'Failed to restart background service';

        // Check if it's a permission issue
        final hasPermissions =
            await BackgroundServiceManager.hasRequiredPermissions();
        if (!hasPermissions) {
          errorMessage = 'Missing required permissions (SMS, Notifications)';
          _currentStatus = _currentStatus.copyWith(
            status: ServiceStatus.permissionDenied,
            lastChecked: DateTime.now(),
            errorMessage: errorMessage,
          );
        } else {
          _currentStatus = _currentStatus.copyWith(
            status: ServiceStatus.error,
            lastChecked: DateTime.now(),
            errorMessage: errorMessage,
          );
        }
      }

      _isLoading = false;
      notifyListeners();

      return success;
    } on TimeoutException catch (e) {
      FlutterLogs.logError(
        _logTag,
        'restartBackgroundService',
        'Service restart timed out: $e',
      );

      _isLoading = false;
      _currentStatus = _currentStatus.copyWith(
        status: ServiceStatus.error,
        lastChecked: DateTime.now(),
        errorMessage: 'Service restart operation timed out. Please try again.',
      );

      notifyListeners();
      return false;
    } catch (e) {
      FlutterLogs.logError(
        _logTag,
        'restartBackgroundService',
        'Error restarting background service: $e',
      );

      _isLoading = false;

      // Provide more specific error messages
      String errorMessage = 'Error restarting service: $e';
      if (e.toString().contains('permission')) {
        errorMessage =
            'Permission denied. Please grant SMS and notification permissions.';
        _currentStatus = _currentStatus.copyWith(
          status: ServiceStatus.permissionDenied,
          lastChecked: DateTime.now(),
          errorMessage: errorMessage,
        );
      } else {
        _currentStatus = _currentStatus.copyWith(
          status: ServiceStatus.error,
          lastChecked: DateTime.now(),
          errorMessage: errorMessage,
        );
      }

      notifyListeners();
      return false;
    }
  }

  /// Checks if the service status has meaningfully changed
  bool _hasStatusChanged(BackgroundServiceStatus newStatus) {
    return _currentStatus.isRunning != newStatus.isRunning ||
        _currentStatus.hasPermissions != newStatus.hasPermissions ||
        _currentStatus.status != newStatus.status ||
        _currentStatus.errorMessage != newStatus.errorMessage;
  }

  /// Attempts automatic service recovery when errors persist
  Future<bool> attemptServiceRecovery() async {
    if (_isLoading) {
      FlutterLogs.logInfo(
        _logTag,
        'attemptServiceRecovery',
        'Service recovery already in progress',
      );
      return false;
    }

    FlutterLogs.logInfo(
      _logTag,
      'attemptServiceRecovery',
      'Attempting automatic service recovery',
    );

    _isLoading = true;
    _currentStatus = _currentStatus.copyWith(
      status: ServiceStatus.starting,
      lastChecked: DateTime.now(),
      errorMessage: 'Attempting service recovery...',
    );
    notifyListeners();

    try {
      final success = await BackgroundServiceManager.attemptServiceRecovery();

      if (success) {
        FlutterLogs.logInfo(
          _logTag,
          'attemptServiceRecovery',
          'Service recovery successful',
        );

        // Reset error counters
        _consecutiveErrors = 0;
        _lastErrorTime = null;

        // Check status to get updated state
        await checkServiceStatus();
      } else {
        FlutterLogs.logError(
          _logTag,
          'attemptServiceRecovery',
          'Service recovery failed',
        );

        _currentStatus = _currentStatus.copyWith(
          status: ServiceStatus.error,
          lastChecked: DateTime.now(),
          errorMessage:
              'Service recovery failed. Please check permissions and try again.',
        );
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      FlutterLogs.logError(
        _logTag,
        'attemptServiceRecovery',
        'Error during service recovery: $e',
      );

      _isLoading = false;
      _currentStatus = _currentStatus.copyWith(
        status: ServiceStatus.error,
        lastChecked: DateTime.now(),
        errorMessage: 'Recovery error: $e',
      );
      notifyListeners();
      return false;
    }
  }

  /// Gets user-friendly error message for current status
  Future<String> getUserFriendlyErrorMessage() async {
    return await BackgroundServiceManager.getUserFriendlyErrorMessage(
      _currentStatus.status,
    );
  }

  /// Performs system diagnostics for troubleshooting
  Future<Map<String, dynamic>> performDiagnostics() async {
    FlutterLogs.logInfo(
      _logTag,
      'performDiagnostics',
      'Performing system diagnostics',
    );

    try {
      final diagnostics =
          await BackgroundServiceManager.performSystemDiagnostics();

      // Add provider-specific diagnostics
      diagnostics['provider'] = {
        'isMonitoring': _isMonitoring,
        'isLoading': _isLoading,
        'consecutiveErrors': _consecutiveErrors,
        'lastErrorTime': _lastErrorTime?.toIso8601String(),
        'currentStatus': _currentStatus.toString(),
        'isAppInBackground': _isAppInBackground,
      };

      FlutterLogs.logInfo(
        _logTag,
        'performDiagnostics',
        'Diagnostics completed with ${diagnostics.keys.length} categories',
      );

      return diagnostics;
    } catch (e) {
      FlutterLogs.logError(
        _logTag,
        'performDiagnostics',
        'Error performing diagnostics: $e',
      );

      return {
        'error': 'Failed to perform diagnostics: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Validates service health and updates status accordingly
  Future<bool> validateServiceHealth() async {
    try {
      FlutterLogs.logInfo(
        _logTag,
        'validateServiceHealth',
        'Validating service health',
      );

      final isHealthy = await BackgroundServiceManager.validateServiceHealth();

      if (!isHealthy && _currentStatus.isHealthy) {
        // Service was healthy but now isn't - update status
        FlutterLogs.logWarn(
          _logTag,
          'validateServiceHealth',
          'Service health validation failed, updating status',
        );

        await checkServiceStatus();
      }

      return isHealthy;
    } catch (e) {
      FlutterLogs.logError(
        _logTag,
        'validateServiceHealth',
        'Error validating service health: $e',
      );
      return false;
    }
  }

  @override
  void dispose() {
    FlutterLogs.logInfo(
      _logTag,
      'dispose',
      'Disposing BackgroundServiceStatusProvider',
    );

    // Set disposed flag to prevent further operations
    _isDisposed = true;

    // Cancel all timers to prevent memory leaks
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;

    _debounceTimer?.cancel();
    _debounceTimer = null;

    // Stop monitoring and cleanup
    if (_isMonitoring) {
      _isMonitoring = false;

      // Unregister from app lifecycle events
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (e) {
        FlutterLogs.logWarn(
          _logTag,
          'dispose',
          'Error removing lifecycle observer: $e',
        );
      }
    }

    // Reset state variables
    _consecutiveErrors = 0;
    _lastErrorTime = null;
    _lastSuccessfulCheck = null;
    _lastNotificationTime = null;
    _notificationCount = 0;

    FlutterLogs.logInfo(
      _logTag,
      'dispose',
      'BackgroundServiceStatusProvider disposed successfully',
    );

    super.dispose();
  }

  /// Provides performance metrics for monitoring and debugging
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'notificationCount': _notificationCount,
      'consecutiveErrors': _consecutiveErrors,
      'lastSuccessfulCheck': _lastSuccessfulCheck?.toIso8601String(),
      'lastErrorTime': _lastErrorTime?.toIso8601String(),
      'isMonitoring': _isMonitoring,
      'isAppInBackground': _isAppInBackground,
      'isAppPaused': _isAppPaused,
      'currentPollingInterval': _determineOptimalPollingInterval().inSeconds,
      'isDisposed': _isDisposed,
    };
  }

  /// Optimizes memory usage by clearing old state when appropriate
  void _optimizeMemoryUsage() {
    if (_isDisposed) return;

    // Reset notification counter periodically to prevent overflow
    if (_notificationCount > 1000) {
      FlutterLogs.logInfo(
        _logTag,
        '_optimizeMemoryUsage',
        'Resetting notification counter for memory optimization',
      );
      _notificationCount = 0;
    }

    // Clear old error times to prevent memory accumulation
    if (_lastErrorTime != null &&
        DateTime.now().difference(_lastErrorTime!).inHours > 24) {
      _lastErrorTime = null;
      _consecutiveErrors = 0;
    }

    // Clear old successful check times if too old
    if (_lastSuccessfulCheck != null &&
        DateTime.now().difference(_lastSuccessfulCheck!).inDays > 7) {
      _lastSuccessfulCheck = null;
    }
  }

  /// Handles memory pressure by reducing resource usage
  void handleMemoryPressure() {
    if (_isDisposed) return;

    FlutterLogs.logInfo(
      _logTag,
      'handleMemoryPressure',
      'Handling memory pressure, optimizing resource usage',
    );

    // Immediately optimize memory
    _optimizeMemoryUsage();

    // Temporarily reduce polling frequency
    if (_isMonitoring && !_isAppInBackground) {
      _statusCheckTimer?.cancel();

      // Use slower polling during memory pressure
      _statusCheckTimer = Timer.periodic(_slowPollingInterval, (_) async {
        if (_isDisposed || !_isMonitoring) return;

        if (!_isAppPaused && !_isAppInBackground) {
          await _checkServiceStatusWithRetry();
        }
      });

      // Resume normal polling after 2 minutes
      Timer(const Duration(minutes: 2), () {
        if (!_isDisposed && _isMonitoring) {
          _statusCheckTimer?.cancel();
          _startAdaptivePolling();
        }
      });
    }
  }

  /// Provides detailed performance and resource usage information
  Map<String, dynamic> getDetailedPerformanceMetrics() {
    final now = DateTime.now();

    return {
      'performance': getPerformanceMetrics(),
      'memory': {
        'isDisposed': _isDisposed,
        'hasActiveTimer': _statusCheckTimer?.isActive ?? false,
        'hasDebounceTimer': _debounceTimer?.isActive ?? false,
        'notificationThrottling': _lastNotificationTime != null,
      },
      'timing': {
        'uptimeMinutes':
            _lastSuccessfulCheck != null
                ? now.difference(_lastSuccessfulCheck!).inMinutes
                : null,
        'errorDurationMinutes':
            _lastErrorTime != null
                ? now.difference(_lastErrorTime!).inMinutes
                : null,
        'currentPollingIntervalSeconds':
            _determineOptimalPollingInterval().inSeconds,
      },
      'state': {
        'serviceHealthy': _currentStatus.isHealthy,
        'monitoringActive': _isMonitoring,
        'appInBackground': _isAppInBackground,
        'appPaused': _isAppPaused,
        'loadingOperation': _isLoading,
      },
    };
  }
}
