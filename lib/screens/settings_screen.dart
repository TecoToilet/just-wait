// screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import '../services/storage_service.dart';
import '../services/accessibility_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Map<String, String>> _blockedApps = [];
  int _sessionMinutes = 5;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await StorageService.getBlockedApps();
    final mins = await StorageService.getSessionMinutes();
    if (mounted) setState(() { _blockedApps = apps; _sessionMinutes = mins; });
  }

  Future<void> _showAppPicker() async {
    setState(() => _loading = true);
    // Get installed apps - filter out system apps
    final List<Application> apps = await DeviceApps.getInstalledApplications(
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );
    apps.sort((a, b) => a.appName.compareTo(b.appName));
    setState(() => _loading = false);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AppPickerSheet(
        apps: apps,
        blockedPackages: _blockedApps.map((a) => a['package']!).toList(),
        onToggle: (pkg, name, add) async {
          if (add) {
            await StorageService.addBlockedApp(pkg, name);
          } else {
            await StorageService.removeBlockedApp(pkg);
          }
          // Update native accessibility service
          final updated = await StorageService.getBlockedApps();
          await AccessibilityBridge.updateBlockedApps(updated.map((a) => a['package']!).toList());
          _load();
        },
      ),
    );
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
              const SizedBox(height: 32),
              // Back
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Text('← back', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF333333), letterSpacing: 1)),
              ),
              const SizedBox(height: 32),
              const Text('settings', style: TextStyle(fontFamily: 'monospace', fontSize: 18, color: Color(0xFF444444), letterSpacing: 2)),
              const SizedBox(height: 40),

              // Session time
              const Text('SESSION DURATION', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF2A2A2A), letterSpacing: 2)),
              const SizedBox(height: 12),
              _buildSessionSlider(),
              const SizedBox(height: 32),

              // Guarded apps
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GUARDED APPS', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF2A2A2A), letterSpacing: 2)),
                  GestureDetector(
                    onTap: _loading ? null : _showAppPicker,
                    child: Text(
                      _loading ? 'loading...' : '+ add',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF333333), letterSpacing: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBlockedList()),

              // Reset today
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  await StorageService.checkDailyReset();
                  // force reset
                  final prefs = await StorageService.getAttempt();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('reset tomorrow at midnight', style: TextStyle(fontFamily: 'monospace', fontSize: 10)),
                      backgroundColor: Color(0xFF111111),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('resets daily at midnight', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF2A2A2A), letterSpacing: 1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_sessionMinutes min full · ${(_sessionMinutes / 2.0).toStringAsFixed(1)} min half',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF444444)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 1,
              activeTrackColor: const Color(0xFF3A3A3A),
              inactiveTrackColor: const Color(0xFF1A1A1A),
              thumbColor: const Color(0xFF555555),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: _sessionMinutes.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              onChanged: (v) async {
                setState(() => _sessionMinutes = v.round());
                await StorageService.setSessionMinutes(v.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedList() {
    if (_blockedApps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
        ),
        child: const Center(
          child: Text(
            'no apps guarded\ntap + add above',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF2A2A2A), height: 1.8),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _blockedApps.length,
      itemBuilder: (_, i) {
        final app = _blockedApps[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(app['name'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF444444))),
              ),
              GestureDetector(
                onTap: () async {
                  await StorageService.removeBlockedApp(app['package']!);
                  final updated = await StorageService.getBlockedApps();
                  await AccessibilityBridge.updateBlockedApps(updated.map((a) => a['package']!).toList());
                  _load();
                },
                child: const Text('remove', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF3A3A3A), letterSpacing: 1)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppPickerSheet extends StatefulWidget {
  final List<Application> apps;
  final List<String> blockedPackages;
  final Function(String pkg, String name, bool add) onToggle;

  const _AppPickerSheet({required this.apps, required this.blockedPackages, required this.onToggle});

  @override
  State<_AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends State<_AppPickerSheet> {
  late List<String> _blocked;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _blocked = [...widget.blockedPackages];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.apps.where((a) => a.appName.toLowerCase().contains(_search.toLowerCase())).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 36, height: 3,
            decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          // Search
          TextField(
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF555555)),
            decoration: const InputDecoration(
              hintText: 'search apps',
              hintStyle: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF2A2A2A)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E1E1E))),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final app = filtered[i];
                final isBlocked = _blocked.contains(app.packageName);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isBlocked) {
                        _blocked.remove(app.packageName);
                      } else {
                        _blocked.add(app.packageName);
                      }
                    });
                    widget.onToggle(app.packageName, app.appName, !isBlocked);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isBlocked ? const Color(0xFF0D1F14) : const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isBlocked ? const Color(0xFF1A3A2A) : const Color(0xFF1A1A1A),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(app.appName, style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: isBlocked ? const Color(0xFF3A7A52) : const Color(0xFF444444))),
                        ),
                        Text(isBlocked ? 'guarded' : '+ guard', style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: isBlocked ? const Color(0xFF2D6E4A) : const Color(0xFF2A2A2A), letterSpacing: 1)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
