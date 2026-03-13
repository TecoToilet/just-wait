// services/accessibility_service.dart
// NOTE: Flutter cannot directly implement Android AccessibilityService.
// The actual AccessibilityService is implemented in Kotlin (Android native).
// This Dart file handles the METHOD CHANNEL communication between
// the Kotlin AccessibilityService and Flutter.

import 'package:flutter/services.dart';
import 'storage_service.dart';

class AccessibilityBridge {
  static const _channel = MethodChannel('com.justwait.app/accessibility');
  static const _eventChannel = EventChannel('com.justwait.app/app_events');

  // Check if accessibility service is enabled
  static Future<bool> isEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isAccessibilityEnabled');
      return result;
    } catch (e) {
      return false;
    }
  }

  // Open Android accessibility settings so user can enable the service
  static Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      // ignore
    }
  }

  // Update the list of blocked apps in the native service
  static Future<void> updateBlockedApps(List<String> packages) async {
    try {
      await _channel.invokeMethod('updateBlockedApps', {'packages': packages});
    } catch (e) {
      // ignore
    }
  }

  // Listen for intercepted app launches
  static Stream<Map<String, String>> get appLaunchStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      return {
        'package': map['package'] as String? ?? '',
        'appName': map['appName'] as String? ?? 'App',
      };
    });
  }
}
