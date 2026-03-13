// screens/session_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:device_apps/device_apps.dart';

class SessionScreen extends StatefulWidget {
  final String package;
  final String appName;
  final bool halfTime;
  final int totalSeconds;

  const SessionScreen({
    super.key,
    required this.package,
    required this.appName,
    required this.halfTime,
    required this.totalSeconds,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> with TickerProviderStateMixin {
  late int _remaining;
  late int _total;
  Timer? _timer;
  late AnimationController _fadeController;
  bool _sessionEnded = false;

  @override
  void initState() {
    super.initState();
    _total = widget.totalSeconds;
    _remaining = _total;
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeController.forward();
    _startTimer();
    _launchApp();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 0) {
        t.cancel();
        setState(() => _sessionEnded = true);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _launchApp() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await DeviceApps.openApp(widget.package);
  }

  String get _timeString {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => _remaining / _total;

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: FadeTransition(
        opacity: _fadeController,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 48),
                // App name
                Text(
                  widget.appName.toLowerCase(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF2A2A2A), letterSpacing: 3),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.halfTime ? 'half session' : 'full session',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: widget.halfTime ? const Color(0xFF5A3A2A) : const Color(0xFF2A4A3A),
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),

                if (!_sessionEnded) ...[
                  // Big timer
                  Text(
                    _timeString,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 52, color: Color(0xFF2A2A2A), letterSpacing: 4),
                  ),
                  const SizedBox(height: 24),
                  // Progress bar
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: const Color(0xFF1A1A1A),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        width: MediaQuery.of(context).size.width * _progress,
                        height: 1,
                        color: widget.halfTime ? const Color(0xFF5A3A2A) : const Color(0xFF2D4A3A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'session active · just wait is watching',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF1E1E1E), letterSpacing: 1),
                  ),
                ] else ...[
                  // Session ended
                  const Text(
                    'session ended.',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 18, color: Color(0xFF444444), fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'the fish are waiting.',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF2A2A2A), fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1E1E1E)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('back', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF333333), letterSpacing: 2)),
                    ),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
