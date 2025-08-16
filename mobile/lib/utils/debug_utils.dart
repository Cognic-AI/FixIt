// Debug logging utility for FixIt app
// This file contains instructions and utilities for debugging

import 'dart:developer' as developer;

/// Debug utility class for FixIt app
class DebugUtils {
  static const String appName = 'FixIt';

  /// Log levels for different types of messages
  static const Map<String, String> logIcons = {
    'info': 'ℹ️',
    'success': '✅',
    'warning': '⚠️',
    'error': '❌',
    'debug': '🐛',
    'navigation': '🧭',
    'firebase': '🔥',
    'api': '📡',
    'ui': '🎨',
    'data': '📊',
  };

  /// Central logging method with consistent formatting
  static void log(
    String message, {
    String category = 'info',
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final icon = logIcons[category] ?? 'ℹ️';
    final logName = name ?? appName;
    developer.log(
      '$icon $message',
      name: logName,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log app lifecycle events
  static void logLifecycle(String event, String component) {
    log('$component: $event', category: 'debug', name: 'Lifecycle');
  }

  /// Log navigation events
  static void logNavigation(String from, String to) {
    log('Navigation: $from → $to', category: 'navigation', name: 'Navigation');
  }

  /// Log API calls
  static void logAPI(String method, String endpoint, {String? status}) {
    final statusText = status != null ? ' ($status)' : '';
    log('$method $endpoint$statusText', category: 'api', name: 'API');
  }

  /// Log Firebase operations
  static void logFirebase(String operation,
      {String? collection, Object? error}) {
    if (error != null) {
      log('Firebase $operation failed: $error',
          category: 'error', name: 'Firebase', error: error);
    } else {
      final collectionText = collection != null ? ' ($collection)' : '';
      log('Firebase $operation$collectionText',
          category: 'firebase', name: 'Firebase');
    }
  }

  /// Log user actions
  static void logUserAction(String action, {Map<String, dynamic>? data}) {
    final dataText = data != null ? ' - ${data.toString()}' : '';
    log('User action: $action$dataText', category: 'info', name: 'UserAction');
  }

  /// Log performance metrics
  static void logPerformance(String operation, Duration duration) {
    log('Performance: $operation took ${duration.inMilliseconds}ms',
        category: 'debug', name: 'Performance');
  }
}

/*
HOW TO VIEW LOGS:

1. FLUTTER LOGS:
   Run your app with: flutter run
   Logs will appear in the terminal/console

2. ANDROID STUDIO / VS CODE:
   - Open Debug Console
   - Run app in debug mode
   - Logs appear in the Debug Console

3. CHROME DEVTOOLS (for web):
   - Press F12 to open DevTools
   - Go to Console tab
   - Filter by "dart.developer" to see only app logs

4. ANDROID DEVICE LOGS:
   - Use: flutter logs
   - Or: adb logcat | grep flutter

5. LOG CATEGORIES USED:
   - Main: App initialization
   - AuthService: Authentication operations
   - HomePage: Home page interactions
   - LoginPage: Login functionality
   - SearchPage: Search operations
   - FirebaseOptions: Firebase configuration
   - Service: Service model operations
   - User: User model operations
   - CustomButton: Button interactions
   - ServiceCard: Service card rendering

EXAMPLE LOG OUTPUTS:
[Main] Starting FixIt App
[AuthService] Attempting sign in with email: user@example.com
[HomePage] Search button pressed - navigating to SearchPage
[FirebaseOptions] Platform detected: Web
[LoginPage] Starting database seeding
[SearchPage] SearchPage initialized

TO ADD MORE LOGGING:
1. Import: import 'dart:developer' as developer;
2. Add logs: developer.log('Your message', name: 'ComponentName');
3. Use emojis for easy visual identification
4. Include relevant context information
*/
