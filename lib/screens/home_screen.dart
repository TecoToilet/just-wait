// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../services/storage_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _accessibilityEnabled = false;
  int _cardCount = 3;
  int _attempt = 1;
  List<Map<String, String>> _blockedApps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await StorageService.checkDailyReset();
    final enabled = await AccessibilityBridge.isEnabled();
    final cards = await StorageService.getCardCount();
    final attempt = await StorageService.getAttempt();
    final apps = await StorageService.getBlockedApps();
    if (mounted) {
      setState(() {
        _accessibilityEnabled = enabled;
        _cardCount = cards;
        _attempt = attempt;
        _blockedApps = apps;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              // Title
              const Text(
                'just wait.',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  color: Color(0xFF555555),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'a fisherman\'s patience for your attention',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Color(0xFF2A2A2A),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 48),

              // Accessibility status
              _buildStatusCard(),
              const SizedBox(height: 24),

              // Today's stats
              _buildStatsRow(),
              const SizedBox(height: 32),

              // Blocked apps
              const Text(
                'GUARDED APPS',
                style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF2A2A2A), letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              _buildBlockedAppsList(),

              const Spacer(),

              // Settings button
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  _load();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'settings',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF444444), letterSpacing: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return GestureDetector(
      onTap: _accessibilityEnabled ? null : () => AccessibilityBridge.openAccessibilitySettings(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _accessibilityEnabled ? const Color(0xFF1A3A2A) : const Color(0xFF3A1A1A),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accessibilityEnabled ? const Color(0xFF2D6E4A) : const Color(0xFF6E2D2D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _accessibilityEnabled
                    ? 'gate is active · watching for guarded apps'
                    : 'tap to enable accessibility service',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF444444), letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStat('attempt', _attempt.toString()),
        const SizedBox(width: 12),
        _buildStat('fish today', _cardCount.toString()),
        const SizedBox(width: 12),
        _buildStat('guarded', _blockedApps.length.toString()),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, color: Color(0xFF444444))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF2A2A2A), letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedAppsList() {
    if (_blockedApps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A1A1A), style: BorderStyle.solid, width: 1),
        ),
        child: const Center(
          child: Text(
            'no apps guarded yet\nadd them in settings',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF2A2A2A), height: 1.8),
          ),
        ),
      );
    }
    return Column(
      children: _blockedApps.map((app) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
        ),
        child: Row(
          children: [
            const Text('·', style: TextStyle(color: Color(0xFF2A2A2A), fontSize: 14)),
            const SizedBox(width: 10),
            Text(
              app['name'] ?? '',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF444444)),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
