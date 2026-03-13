// android/app/src/main/kotlin/com/justwait/app/JustWaitAccessibilityService.kt
package com.justwait.app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.content.SharedPreferences
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray

class JustWaitAccessibilityService : AccessibilityService() {

    private lateinit var prefs: SharedPreferences
    private var lastInterceptedPackage = ""
    private var lastInterceptedTime = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val info = AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
        info.notificationTimeout = 100
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val packageName = event.packageName?.toString() ?: return

        // Ignore our own app and system
        if (packageName == "com.justwait.app") return
        if (packageName == "com.android.launcher" || packageName == "com.miui.home") return

        // Check if this package is blocked
        if (!isPackageBlocked(packageName)) return

        // Debounce - don't intercept same app twice within 500ms
        val now = System.currentTimeMillis()
        if (packageName == lastInterceptedPackage && now - lastInterceptedTime < 500) return
        lastInterceptedPackage = packageName
        lastInterceptedTime = now

        // Get app name
        val appName = try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
        }

        // Launch Just Wait gate over the intercepted app
        val intent = Intent(this, MainActivity::class.java).apply {
            action = "JUST_WAIT_INTERCEPT"
            putExtra("package", packageName)
            putExtra("appName", appName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        startActivity(intent)
    }

    private fun isPackageBlocked(packageName: String): Boolean {
        val raw = prefs.getString("flutter.blocked_apps", "[]") ?: "[]"
        return try {
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                if (obj.getString("package") == packageName) return true
            }
            false
        } catch (e: Exception) {
            false
        }
    }

    override fun onInterrupt() {}
}
