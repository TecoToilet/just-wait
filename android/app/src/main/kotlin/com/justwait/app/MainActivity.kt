// android/app/src/main/kotlin/com/justwait/app/MainActivity.kt
package com.justwait.app

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.justwait.app/accessibility"
    private val EVENT_CHANNEL = "com.justwait.app/app_events"
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel - Dart calls into Android
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" -> result.success(isAccessibilityEnabled())
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "updateBlockedApps" -> {
                        // Already stored in SharedPreferences via flutter, just acknowledge
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Event channel - Android pushes intercepted app launches to Dart
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    // If app was launched by accessibility service, fire immediately
                    handleInterceptIntent(intent)
                }
                override fun onCancel(arguments: Any?) { eventSink = null }
            })
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleInterceptIntent(intent)
    }

    private fun handleInterceptIntent(intent: Intent?) {
        if (intent?.action == "JUST_WAIT_INTERCEPT") {
            val pkg = intent.getStringExtra("package") ?: return
            val name = intent.getStringExtra("appName") ?: pkg
            eventSink?.success(mapOf("package" to pkg, "appName" to name))
        }
    }

    private fun isAccessibilityEnabled(): Boolean {
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabledServices.contains("com.justwait.app/com.justwait.app.JustWaitAccessibilityService")
    }
}
