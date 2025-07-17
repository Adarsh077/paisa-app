import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/background_service_status_provider.dart';
import '../services/background_service_manager.dart' as service_manager;

/// Widget that displays the background service status as a circular indicator
/// in the app bar with tap-to-restart functionality
class BackgroundServiceStatusWidget extends StatelessWidget {
  const BackgroundServiceStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BackgroundServiceStatusProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: () => _handleTap(context, provider),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: Center(child: _buildStatusIndicator(context, provider)),
          ),
        );
      },
    );
  }

  /// Builds the appropriate status indicator based on current state
  Widget _buildStatusIndicator(
    BuildContext context,
    BackgroundServiceStatusProvider provider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (provider.isLoading) {
      return _buildLoadingIndicator(colorScheme);
    }

    return _buildStatusCircle(context, provider, colorScheme);
  }

  /// Builds the loading animation indicator
  Widget _buildLoadingIndicator(ColorScheme colorScheme) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
      ),
    );
  }

  /// Builds the status circle (green/red) based on service state
  Widget _buildStatusCircle(
    BuildContext context,
    BackgroundServiceStatusProvider provider,
    ColorScheme colorScheme,
  ) {
    Color circleColor;
    IconData? icon;

    if (provider.isHealthy) {
      // Service is running and healthy - green circle
      circleColor = Colors.green;
    } else if (provider.serviceStatus ==
        service_manager.ServiceStatus.permissionDenied) {
      // Permission denied - orange/amber circle with warning icon
      circleColor = Colors.amber;
      icon = Icons.warning;
    } else if (provider.serviceStatus == service_manager.ServiceStatus.error) {
      // Error state - red circle with error icon
      circleColor = Colors.red;
      icon = Icons.error;
    } else {
      // Service stopped - red circle
      circleColor = Colors.red;
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleColor,
        boxShadow: [
          BoxShadow(
            color: circleColor.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: icon != null ? Icon(icon, size: 10, color: Colors.white) : null,
    );
  }

  /// Handles tap events on the status indicator
  void _handleTap(
    BuildContext context,
    BackgroundServiceStatusProvider provider,
  ) {
    // Only allow tap when service is not running and not loading
    if (provider.isHealthy || provider.isLoading) {
      return;
    }

    // Provide immediate visual feedback
    _showTapFeedback(context, provider);

    // Attempt to restart the service (more robust than just start)
    _restartService(context, provider);
  }

  /// Shows immediate visual feedback for tap action
  void _showTapFeedback(
    BuildContext context,
    BackgroundServiceStatusProvider provider,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Determine appropriate message based on current status
    String message = 'Starting service...';
    if (provider.serviceStatus == service_manager.ServiceStatus.error) {
      message = 'Restarting service...';
    } else if (provider.serviceStatus ==
        service_manager.ServiceStatus.permissionDenied) {
      message = 'Checking permissions...';
    }

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top - 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onInverseSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onInverseSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    // Remove the feedback after a short delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Attempts to restart the background service with comprehensive error handling
  Future<void> _restartService(
    BuildContext context,
    BackgroundServiceStatusProvider provider,
  ) async {
    try {
      // First attempt normal restart
      bool success = await provider.restartBackgroundService();

      if (!context.mounted) return;

      if (success) {
        _showSuccessSnackBar(
          context,
          'Background service restarted successfully',
        );
        return;
      }

      // If normal restart failed, try recovery
      if (provider.serviceStatus == service_manager.ServiceStatus.error) {
        _showRecoveryDialog(context, provider);
      } else {
        final errorMessage = await provider.getUserFriendlyErrorMessage();
        if (context.mounted) {
          _showErrorSnackBar(context, errorMessage, provider.serviceStatus);
        }
      }
    } catch (e) {
      if (!context.mounted) return;

      _showErrorSnackBar(
        context,
        'Error restarting service: $e',
        service_manager.ServiceStatus.error,
      );
    }
  }

  /// Shows a recovery dialog with advanced options
  void _showRecoveryDialog(
    BuildContext context,
    BackgroundServiceStatusProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.healing, color: Colors.orange),
              SizedBox(width: 8),
              Text('Service Recovery'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The background service is experiencing issues. Would you like to try advanced recovery?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('This will:', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('• Perform system diagnostics'),
              Text('• Attempt service recovery'),
              Text('• Check device-specific issues'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDiagnosticsDialog(context, provider);
              },
              child: const Text('View Diagnostics'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _attemptServiceRecovery(context, provider);
              },
              child: const Text('Try Recovery'),
            ),
          ],
        );
      },
    );
  }

  /// Shows system diagnostics dialog
  void _showDiagnosticsDialog(
    BuildContext context,
    BackgroundServiceStatusProvider provider,
  ) async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Running diagnostics...'),
              ],
            ),
          ),
    );

    try {
      final diagnostics = await provider.performDiagnostics();

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show diagnostics results
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text('System Diagnostics'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDiagnosticSection('Service Status', {
                      'Running':
                          diagnostics['serviceRunning']?.toString() ??
                          'Unknown',
                      'Permissions':
                          diagnostics['hasPermissions']?.toString() ??
                          'Unknown',
                    }),
                    const SizedBox(height: 12),
                    _buildDiagnosticSection(
                      'Device Info',
                      diagnostics['device'] as Map<String, dynamic>? ?? {},
                    ),
                    const SizedBox(height: 12),
                    _buildDiagnosticSection(
                      'Permissions',
                      diagnostics['permissions'] as Map<String, dynamic>? ?? {},
                    ),
                    if (diagnostics['provider'] != null) ...[
                      const SizedBox(height: 12),
                      _buildDiagnosticSection(
                        'Provider Status',
                        diagnostics['provider'] as Map<String, dynamic>,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    _attemptServiceRecovery(context, provider);
                  }
                },
                child: const Text('Try Recovery'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Failed to run diagnostics: $e',
          service_manager.ServiceStatus.error,
        );
      }
    }
  }

  /// Builds a diagnostic section widget
  Widget _buildDiagnosticSection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        ...data.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '${entry.key}: ${entry.value}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Attempts service recovery with user feedback
  Future<void> _attemptServiceRecovery(
    BuildContext context,
    BackgroundServiceStatusProvider provider,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Attempting service recovery...'),
              ],
            ),
          ),
    );

    try {
      final success = await provider.attemptServiceRecovery();

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      if (!context.mounted) return;

      if (success) {
        _showSuccessSnackBar(
          context,
          'Service recovery successful! Background monitoring is now active.',
        );
      } else {
        final errorMessage = await provider.getUserFriendlyErrorMessage();
        if (context.mounted) {
          _showErrorSnackBar(
            context,
            'Recovery failed: $errorMessage',
            provider.serviceStatus,
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Recovery error: $e',
          service_manager.ServiceStatus.error,
        );
      }
    }
  }

  /// Shows a success snack bar with green styling
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Shows an error snack bar with appropriate styling and action buttons
  void _showErrorSnackBar(
    BuildContext context,
    String message,
    service_manager.ServiceStatus status,
  ) {
    IconData icon = Icons.error;
    Color backgroundColor = Colors.red;
    String actionLabel = 'Retry';

    // Customize based on error type
    if (status == service_manager.ServiceStatus.permissionDenied) {
      icon = Icons.warning;
      backgroundColor = Colors.orange;
      actionLabel = 'Settings';
    } else if (status == service_manager.ServiceStatus.error) {
      icon = Icons.error_outline;
      backgroundColor = Colors.red;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: () {
            if (status == service_manager.ServiceStatus.permissionDenied) {
              _openAppSettings(context);
            } else {
              // Retry the operation
              final provider = Provider.of<BackgroundServiceStatusProvider>(
                context,
                listen: false,
              );
              _restartService(context, provider);
            }
          },
        ),
      ),
    );
  }

  /// Opens app settings for permission management
  Future<void> _openAppSettings(BuildContext context) async {
    try {
      final opened = await openAppSettings();

      if (!opened) {
        // Fallback if opening settings fails
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Please grant SMS and Notification permissions in Settings > Apps > Paisa > Permissions',
              ),
              duration: const Duration(seconds: 8),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        // Show a brief message that settings were opened
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Opening app settings...'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Handle error opening settings
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening settings: $e'),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
