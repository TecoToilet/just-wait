// screens/gate_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/fish_painter.dart';
import '../services/storage_service.dart';

// Memorize sub-phases for the card reveal sequence
enum MemorizeSubPhase {
  allClosed,       // all cards face down
  openingReveal,   // cards flip open one by one
  allOpen,         // all cards visible, timer running
  closingHide,     // cards flip closed one by one
  allClosed2,      // brief pause closed
  shuffling,       // cards slide/reorder while closed
  openingFinal,    // cards flip open again in NEW shuffled order
  allOpenFinal,    // user sees shuffled open cards, timer running
}

enum GatePhase { memorize, arrange, resultPass, resultFail, opening }

class GateScreen extends StatefulWidget {
  final String interceptedPackage;
  final String appName;

  const GateScreen({
    super.key,
    required this.interceptedPackage,
    required this.appName,
  });

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> with TickerProviderStateMixin {
  GatePhase _phase = GatePhase.memorize;
  MemorizeSubPhase _subPhase = MemorizeSubPhase.allClosed;

  List<int> _sequence = [];       // original order
  List<int> _displayOrder = [];   // shuffled display order shown in memorize
  List<int?> _slots = [];
  List<bool> _cardUsed = [];
  int _cardCount = 3;
  int _attempt = 1;

  // Which cards are currently face-up (by display index)
  List<bool> _cardFaceUp = [];

  // Timer bar controller (runs during allOpenFinal)
  late AnimationController _timerController;

  // Hook animation controllers
  late AnimationController _hookDescendController;
  late AnimationController _hookAscendController;
  late AnimationController _overlaySlideController;
  late Animation<double> _overlaySlide;
  bool _hookBroken = false;

  // Result fade
  late AnimationController _resultFadeController;
  late Animation<double> _resultFade;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadAndStart();
  }

  void _initControllers() {
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _hookDescendController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _hookAscendController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _overlaySlideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _overlaySlide = Tween<double>(begin: 0.0, end: -1.1).animate(
      CurvedAnimation(parent: _overlaySlideController, curve: Curves.easeInCubic),
    );
    _resultFadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _resultFade = CurvedAnimation(parent: _resultFadeController, curve: Curves.easeIn);
  }

  Future<void> _loadAndStart() async {
    await StorageService.checkDailyReset();
    _cardCount = await StorageService.getCardCount();
    _attempt = await StorageService.getAttempt();
    _startMemorize();
  }

  Future<void> _startMemorize() async {
    final rng = math.Random();
    final pool = List.generate(8, (i) => i)..shuffle(rng);
    _sequence = pool.sublist(0, _cardCount);
    _displayOrder = List.from(_sequence); // starts same as sequence
    _slots = List.filled(_cardCount, null);
    _cardUsed = List.filled(_cardCount, false);
    _cardFaceUp = List.filled(_cardCount, false);

    setState(() {
      _phase = GatePhase.memorize;
      _subPhase = MemorizeSubPhase.allClosed;
    });

    // Run the full reveal sequence
    await _runRevealSequence();
  }

  Future<void> _runRevealSequence() async {
    // 1. Brief pause with all closed
    await Future.delayed(const Duration(milliseconds: 400));

    // 2. Open cards one by one (left to right)
    setState(() => _subPhase = MemorizeSubPhase.openingReveal);
    for (int i = 0; i < _cardCount; i++) {
      await Future.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      setState(() => _cardFaceUp[i] = true);
    }

    // 3. All open - timer runs so user can memorize
    setState(() => _subPhase = MemorizeSubPhase.allOpen);
    _timerController.reset();
    await Future.delayed(const Duration(milliseconds: 200));
    // Show for 3 seconds
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted || _phase != GatePhase.memorize) return;

    // 4. Close cards one by one (left to right)
    setState(() => _subPhase = MemorizeSubPhase.closingHide);
    for (int i = 0; i < _cardCount; i++) {
      await Future.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
      setState(() => _cardFaceUp[i] = false);
    }

    // 5. Brief pause all closed
    setState(() => _subPhase = MemorizeSubPhase.allClosed2);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // 6. Shuffle the display order while closed
    setState(() {
      _subPhase = MemorizeSubPhase.shuffling;
      _displayOrder = List.from(_sequence)..shuffle(math.Random());
      _cardFaceUp = List.filled(_cardCount, false);
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // 7. Open cards one by one in the NEW shuffled order
    setState(() => _subPhase = MemorizeSubPhase.openingFinal);
    for (int i = 0; i < _cardCount; i++) {
      await Future.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      setState(() => _cardFaceUp[i] = true);
    }

    // 8. All open final - timer bar runs, user must memorize shuffled order
    setState(() => _subPhase = MemorizeSubPhase.allOpenFinal);
    _timerController.reset();
    _timerController.forward().then((_) {
      if (_phase == GatePhase.memorize) _showArrange();
    });
  }

  void _showArrange() {
    _timerController.stop();
    setState(() => _phase = GatePhase.arrange);
  }

  void _placeCard(int shuffledIdx) {
    if (_cardUsed[shuffledIdx]) return;
    final nextSlot = _slots.indexWhere((s) => s == null);
    if (nextSlot == -1) return;
    setState(() {
      _slots[nextSlot] = _displayOrder[shuffledIdx];
      _cardUsed[shuffledIdx] = true;
    });
  }

  void _resetArrange() {
    setState(() {
      _slots = List.filled(_cardCount, null);
      _cardUsed = List.filled(_cardCount, false);
    });
  }

  void _checkAnswer() {
    if (_slots.contains(null)) return;
    // Compare slots against ORIGINAL sequence order
    final correct = List.generate(_cardCount, (i) => _slots[i] == _sequence[i]).every((v) => v);
    if (correct) {
      _onPass();
    } else {
      _onFail();
    }
  }

  void _onPass() async {
    setState(() { _phase = GatePhase.resultPass; _hookBroken = false; });
    _resultFadeController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    await _hookDescendController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _hookAscendController.forward();
    _overlaySlideController.forward().then((_) {
      setState(() => _phase = GatePhase.opening);
      _openTargetApp();
    });
  }

  void _onFail() async {
    await StorageService.incrementAfterFail();
    setState(() { _phase = GatePhase.resultFail; _hookBroken = false; });
    _resultFadeController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    await _hookDescendController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _hookBroken = true);
    await _hookAscendController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _openTargetApp(halfTime: true);
  }

  void _openTargetApp({bool halfTime = false}) async {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/session', arguments: {
        'package': widget.interceptedPackage,
        'appName': widget.appName,
        'halfTime': halfTime,
      });
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    _hookDescendController.dispose();
    _hookAscendController.dispose();
    _overlaySlideController.dispose();
    _resultFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          _buildMainContent(screenW, screenH),

          if (_phase == GatePhase.resultPass || _phase == GatePhase.resultFail || _phase == GatePhase.opening)
            AnimatedBuilder(
              animation: _overlaySlide,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _overlaySlide.value * screenH),
                child: _buildResultOverlay(screenW, screenH),
              ),
            ),

          if (_phase == GatePhase.resultPass || _phase == GatePhase.resultFail)
            AnimatedBuilder(
              animation: Listenable.merge([_hookDescendController, _hookAscendController]),
              builder: (_, __) {
                double top;
                if (_hookAscendController.value > 0) {
                  top = (1 - _hookAscendController.value) * (screenH * 0.45) - 120;
                } else {
                  top = _hookDescendController.value * (screenH * 0.45) - 120;
                }
                return Positioned(
                  top: top,
                  left: screenW / 2 - 12,
                  child: _buildHook(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHook() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 1, height: 80, color: _hookBroken ? const Color(0xFF2A2A2A) : const Color(0xFF555555)),
        CustomPaint(size: const Size(24, 32), painter: _HookPainter(broken: _hookBroken)),
      ],
    );
  }

  Widget _buildMainContent(double w, double h) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, right: 20),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'attempt $_attempt · $_cardCount fish',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF2A2A2A), letterSpacing: 1.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.appName.toLowerCase(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF333333), letterSpacing: 3),
            ),
          ),
          const Spacer(),
          if (_phase == GatePhase.memorize) _buildMemorizePhase(),
          if (_phase == GatePhase.arrange) _buildArrangePhase(),
          const Spacer(),
        ],
      ),
    );
  }

  // ─── Memorize Phase ──────────────────────────────────────────────────────────

  String get _memorizeLabel {
    switch (_subPhase) {
      case MemorizeSubPhase.allClosed:
      case MemorizeSubPhase.openingReveal:
        return 'watch carefully';
      case MemorizeSubPhase.allOpen:
        return 'memorize the order';
      case MemorizeSubPhase.closingHide:
        return 'closing...';
      case MemorizeSubPhase.allClosed2:
      case MemorizeSubPhase.shuffling:
        return 'shuffling...';
      case MemorizeSubPhase.openingFinal:
        return 'now memorize this order';
      case MemorizeSubPhase.allOpenFinal:
        return 'memorize the order';
    }
  }

  Widget _buildMemorizePhase() {
    final showTimer = _subPhase == MemorizeSubPhase.allOpenFinal;
    final isShuffling = _subPhase == MemorizeSubPhase.shuffling || _subPhase == MemorizeSubPhase.allClosed2;

    return Column(
      children: [
        Text(
          _memorizeLabel.toUpperCase(),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF2E2E2E), letterSpacing: 2),
        ),
        const SizedBox(height: 14),

        // Timer bar - only visible during final memorize window
        AnimatedOpacity(
          opacity: showTimer ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedBuilder(
            animation: _timerController,
            builder: (_, __) => Container(
              width: 200,
              height: 1,
              color: const Color(0xFF1A1A1A),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 200 * (1 - _timerController.value),
                  height: 1,
                  color: const Color(0xFF3A3A3A),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Fish cards row with flip animation
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(_cardCount, (i) {
            final fishId = _displayOrder.isNotEmpty ? _displayOrder[i] : _sequence[i];
            return _FlipCard(
              fishId: fishId,
              isFaceUp: _cardFaceUp.isNotEmpty ? _cardFaceUp[i] : false,
              isShuffling: isShuffling,
            );
          }),
        ),

        const SizedBox(height: 14),
        Text(
          _memorizeLabel,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF383838)),
        ),
      ],
    );
  }

  // ─── Arrange Phase ───────────────────────────────────────────────────────────

  Widget _buildArrangePhase() {
    return Column(
      children: [
        const Text(
          'RECREATE THE ORIGINAL ORDER',
          style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF2E2E2E), letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        _buildSlotRow(),
        const SizedBox(height: 14),
        const Text(
          'tap fish in correct order',
          style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF444444)),
        ),
        const SizedBox(height: 14),
        // Show shuffled display order for tapping
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(_cardCount, (i) {
            return FishCard(
              fishId: _displayOrder[i],
              isDim: _cardUsed[i],
              onTap: () => _placeCard(i),
            );
          }),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBtn('confirm', _checkAnswer),
            const SizedBox(width: 10),
            _buildBtn('reset', _resetArrange),
          ],
        ),
      ],
    );
  }

  Widget _buildSlotRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(_cardCount, (i) {
        final filled = _slots[i] != null;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 58,
          height: 72,
          decoration: BoxDecoration(
            color: filled ? const Color(0xFF161616) : const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: filled ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: filled ? CustomPaint(painter: FishPainter(fishId: _slots[i]!)) : null,
        );
      }),
    );
  }

  // ─── Result Overlay ──────────────────────────────────────────────────────────

  Widget _buildResultOverlay(double w, double h) {
    final isPass = _phase == GatePhase.resultPass || _phase == GatePhase.opening;
    return Container(
      width: w,
      height: h,
      color: const Color(0xFF0D0D0D),
      child: FadeTransition(
        opacity: _resultFade,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isPass ? 'you have passed.' : 'you have failed,',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Color(0xFF555555), fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 6),
            Text(
              isPass ? 'your focus is clear.' : 'yet you shall still earn half.',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Color(0xFFAAAAAA), fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            FutureBuilder<int>(
              future: StorageService.getSessionMinutes(),
              builder: (_, snap) {
                final mins = snap.data ?? 5;
                final grantedMins = isPass ? mins : (mins / 2).floor();
                final grantedSecs = isPass ? 0 : (((mins * 60) / 2) % 60).floor();
                final timeStr = grantedSecs > 0
                    ? '${grantedMins}:${grantedSecs.toString().padLeft(2, '0')} granted'
                    : '${grantedMins}:00 granted';
                return Text(
                  timeStr,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF2E2E2E), letterSpacing: 2),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF1E1E1E), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF555555), letterSpacing: 1),
        ),
      ),
    );
  }
}

// ─── Flip Card Widget ─────────────────────────────────────────────────────────
// Animates between face-down (dark back) and face-up (fish visible)

class _FlipCard extends StatefulWidget {
  final int fishId;
  final bool isFaceUp;
  final bool isShuffling;

  const _FlipCard({
    required this.fishId,
    required this.isFaceUp,
    required this.isShuffling,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _flipAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    if (widget.isFaceUp) _flipController.value = 1.0;
  }

  @override
  void didUpdateWidget(_FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.isFaceUp != old.isFaceUp) {
      if (widget.isFaceUp) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnim,
      builder: (_, __) {
        final angle = _flipAnim.value * math.pi;
        final isFrontVisible = _flipAnim.value >= 0.5;

        // Subtle bounce when shuffling
        final shuffleOffset = widget.isShuffling
            ? math.sin(_flipController.value * math.pi * 3) * 3.0
            : 0.0;

        return Transform.translate(
          offset: Offset(0, shuffleOffset),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(isFrontVisible ? angle - math.pi : angle),
            child: isFrontVisible ? _buildFront() : _buildBack(),
          ),
        );
      },
    );
  }

  Widget _buildFront() {
    return Container(
      width: 58,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFF252525), width: 1.0),
      ),
      padding: const EdgeInsets.all(8),
      child: CustomPaint(painter: FishPainter(fishId: widget.fishId)),
    );
  }

  Widget _buildBack() {
    return Container(
      width: 58,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.0),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(20, 20),
          painter: _CardBackPainter(),
        ),
      ),
    );
  }
}

// Minimal card back design - just a small fish silhouette outline
class _CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    // Simple fish outline as card back mark
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width*0.44, size.height*0.5), width: size.width*0.7, height: size.height*0.55), paint);
    final tail = Path()
      ..moveTo(size.width*0.76, size.height*0.5)
      ..lineTo(size.width*0.98, size.height*0.15)
      ..lineTo(size.width*0.98, size.height*0.85)
      ..close();
    canvas.drawPath(tail, paint);
  }
  @override
  bool shouldRepaint(_CardBackPainter old) => false;
}

// Hook painter
class _HookPainter extends CustomPainter {
  final bool broken;
  const _HookPainter({this.broken = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final paint = Paint()
      ..color = broken ? const Color(0xFF2A2A2A) : const Color(0xFF666666)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    if (broken) {
      canvas.drawLine(Offset(w*0.5, 0), Offset(w*0.5, h*0.3), paint);
      canvas.drawLine(Offset(w*0.52, h*0.42), Offset(w*0.5, h*0.62), paint);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w*0.66, h*0.65), width: w*0.6, height: h*0.52),
        math.pi, math.pi * 0.75, false, paint,
      );
    } else {
      canvas.drawLine(Offset(w*0.5, 0), Offset(w*0.5, h*0.52), paint);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w*0.66, h*0.62), width: w*0.6, height: h*0.55),
        math.pi, math.pi * 0.85, false, paint,
      );
      final barb = Path()
        ..moveTo(w*0.94, h*0.74)
        ..lineTo(w*0.72, h*0.60)
        ..lineTo(w*0.90, h*0.54);
      canvas.drawPath(barb, paint);
    }
  }

  @override
  bool shouldRepaint(_HookPainter old) => old.broken != broken;
}
