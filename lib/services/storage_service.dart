// services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const _keyAttempt = 'attempt_count';
  static const _keyCardCount = 'card_count';
  static const _keyLastReset = 'last_reset_date';
  static const _keyBlockedApps = 'blocked_apps';
  static const _keySessionMinutes = 'session_minutes';
  static const _keyHalfSessionMinutes = 'half_session_minutes';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Daily reset check - resets card count and attempt at midnight
  static Future<void> checkDailyReset() async {
    final prefs = await _prefs;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastReset = prefs.getString(_keyLastReset) ?? '';
    if (lastReset != todayStr) {
      await prefs.setInt(_keyAttempt, 1);
      await prefs.setInt(_keyCardCount, 3);
      await prefs.setString(_keyLastReset, todayStr);
    }
  }

  static Future<int> getAttempt() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyAttempt) ?? 1;
  }

  static Future<int> getCardCount() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyCardCount) ?? 3;
  }

  static Future<void> incrementAfterFail() async {
    final prefs = await _prefs;
    final current = prefs.getInt(_keyAttempt) ?? 1;
    final cards = prefs.getInt(_keyCardCount) ?? 3;
    await prefs.setInt(_keyAttempt, current + 1);
    // cap at 8 fish
    if (cards < 8) {
      await prefs.setInt(_keyCardCount, cards + 1);
    }
  }

  static Future<List<Map<String, String>>> getBlockedApps() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyBlockedApps) ?? '[]';
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map<Map<String, String>>((e) => Map<String, String>.from(e)).toList();
  }

  static Future<void> addBlockedApp(String packageName, String appName) async {
    final prefs = await _prefs;
    final apps = await getBlockedApps();
    if (!apps.any((a) => a['package'] == packageName)) {
      apps.add({'package': packageName, 'name': appName});
      await prefs.setString(_keyBlockedApps, jsonEncode(apps));
    }
  }

  static Future<void> removeBlockedApp(String packageName) async {
    final prefs = await _prefs;
    final apps = await getBlockedApps();
    apps.removeWhere((a) => a['package'] == packageName);
    await prefs.setString(_keyBlockedApps, jsonEncode(apps));
  }

  static Future<bool> isAppBlocked(String packageName) async {
    final apps = await getBlockedApps();
    return apps.any((a) => a['package'] == packageName);
  }

  static Future<int> getSessionMinutes() async {
    final prefs = await _prefs;
    return prefs.getInt(_keySessionMinutes) ?? 5;
  }

  static Future<void> setSessionMinutes(int minutes) async {
    final prefs = await _prefs;
    await prefs.setInt(_keySessionMinutes, minutes);
  }
}
