// widgets/fish_painter.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class FishPainter extends CustomPainter {
  final int fishId;
  final Color bodyColor;
  final Color finColor;
  final Color eyeColor;

  const FishPainter({
    required this.fishId,
    this.bodyColor = const Color(0xFF2E2E2E),
    this.finColor = const Color(0xFF3A3A3A),
    this.eyeColor = const Color(0xFF0D0D0D),
  });

  Paint get _body => Paint()..color = bodyColor..style = PaintingStyle.fill;
  Paint get _fin => Paint()..color = finColor..style = PaintingStyle.fill;
  Paint get _outline => Paint()..color = const Color(0xFF484848)..style = PaintingStyle.stroke..strokeWidth = 1.4;
  Paint get _eye => Paint()..color = eyeColor..style = PaintingStyle.fill;
  Paint get _shine => Paint()..color = const Color(0xFF777777)..style = PaintingStyle.fill;
  Paint get _scale => Paint()..color = const Color(0xFF3A3A3A)..style = PaintingStyle.stroke..strokeWidth = 0.9;

  @override
  void paint(Canvas canvas, Size size) {
    switch (fishId % 8) {
      case 0: _tuna(canvas, size); break;
      case 1: _flounder(canvas, size); break;
      case 2: _eel(canvas, size); break;
      case 3: _puffer(canvas, size); break;
      case 4: _angel(canvas, size); break;
      case 5: _sword(canvas, size); break;
      case 6: _ray(canvas, size); break;
      case 7: _arrow(canvas, size); break;
    }
  }

  void _tuna(Canvas c, Size s) {
    final w = s.width; final h = s.height;
    c.drawPath(Path()
      ..moveTo(w*0.72, h*0.5)
      ..lineTo(w*0.96, h*0.08)
      ..lineTo(w*0.96, h*0.92)
      ..close(), _fin);
    final body = Path()..addOval(Rect.fromCenter(center: Offset(w*0.42, h*0.5), width: w*0.74, height: h*0.80));
    c.drawPath(body, _body);
    c.drawPath(body, _outline);
    c.drawPath(Path()
      ..moveTo(w*0.24, h*0.18)
      ..quadraticBezierTo(w*0.44, h*0.0, w*0.62, h*0.2)
      ..lineTo(w*0.62, h*0.26)
      ..lineTo(w*0.24, h*0.24)
      ..close(), _fin);
    for (int i = 0; i < 3; i++) {
      c.drawArc(Rect.fromCenter(center: Offset(w*(0.30+i*0.11), h*0.5), width: w*0.18, height: h*0.52), -1.1, 2.2, false, _scale);
    }
    c.drawCircle(Offset(w*0.16, h*0.38), w*0.072, _eye);
    c.drawCircle(Offset(w*0.14, h*0.34), w*0.024, _shine);
  }

  void _flounder(Canvas c, Size s) {
    final w = s.width; final h = s.height;
    c.drawPath(Path()
      ..moveTo(w*0.28, h*0.5)
      ..lineTo(w*0.04, h*0.08)
      ..lineTo(w*0.04, h*0.92)
      ..close(), _fin);
    final body = Path()..addOval(Rect.fromCenter(center: Offset(w*0.58, h*0.5), width: w*0.80, height: h*0.68));
    c.drawPath(body, _body);
    c.drawPath(body, _outline);
    c.drawPath(Path()
      ..moveTo(w*0.36, h*0.17)
      ..quadraticBezierTo(w*0.6, h*0.0, w*0.84, h*0.19)
      ..lineTo(w*0.84, h*0.25)
      ..lineTo(w*0.36, h*0.23)
      ..close(), _fin);
    for (int i = 0; i < 3; i++) {
      c.drawArc(Rect.fromCenter(center: Offset(w*(0.44+i*0.11), h*0.5), width: w*0.17, height: h*0.46), 0.9, 2.4, false, _scale);
    }
    c.drawCircle(Offset(w*0.83, h*0.37), w*0.068, _eye);
    c.drawCircle(Offset(w*0.85, h*0.33), w*0.023, _shine);
  }

  void _eel(Canvas c, Size s) {
    final w = s.width; final h = s.height;
    c.drawPath(Path()
      ..moveTo(w*0.84, h*0.5)
      ..lineTo(w*0.98, h*0.25)
      ..lineTo(w*0.98, h*0.75)
      ..close(), _fin);
    final body = Path()..addOval(Rect.fromCenter(center: Offset(w*0.44, h*0.5), width: w*0.84, height: h*0.40));
    c.drawPath(body, _body);
    c.drawPath(body, _outline);
    for (int i = 0; i < 4; i++) {
      c.drawArc(Rect.fromCenter(center: Offset(w*(0.20+i*0.14), h*0.5), width: w*0.13, height: h*0.34), -1.2, 2.4, false, _scale);
    }
    c.drawCircle(Offset(w*0.10, h*0.42), w*0.058, _eye);
    c.drawCircle(Offset(w*0.08, h*0.38), w*0.019, _shine);
  }

  void _puffer(Canvas c, Size s) {
    final w = s.width; final h = s.height;
    c.drawPath(Path()
      ..moveTo(w*0.30, h*0.5)
      ..lineTo(w*0.04, h*0.14)
      ..lineTo(w*0.04, h*0.86)
      ..close(), _fin);
    final body = Path()..addOval(Rect.fromCenter(center: Offset(w*0.58, h*0.5), width: w*0.74, height: h*0.90));
    c.drawPath(body, _body);
    c.drawPath(body, _outline);
    final spinePaint = Paint()..color = const Color(0xFF555555)..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final angle = -math.pi*0.55 + i * (math.pi*1.1 / 5);
      final cx = w*0.58 + (w*0.37) * math.cos(angle);
      final cy = h*0.5 + (h*0.45) * math.sin(angle);
      c.drawLine(Offset(cx, cy), Offset(cx + w*0.08*math.cos(angle), cy + h*0.08*math.sin(angle)), spinePaint);
    }
    c.drawCircle(Offset(w*0.82, h*0.38), w*0.072, _eye);
    c.drawCircle(Offset(w*0.84, h*0.34), w*0.024, _shine);
  }

  void _angel(Canvas c, Size s) {
    final w = s.width; final h = s.height;
    c.drawPath(Path()
      ..moveTo(w*0.5, h*0.80)
      ..lineTo(w*0.08, h*0.97)
      ..lineTo(w*0.92, h*0.97)
      ..close(), _fin);
    final body = Path()..addOval(Rect.fromCenter(center: Offset(w*0.5, h*0.44), width: w*0.60, height: h*0.74));
    c.drawPath(body, _body);
    c.drawPath(body, _outline);
    c.drawPath(Path()
      ..moveTo(w*0.20, h*0.38)
      ..quadraticBezierTo(w*0.0, h*0.62, w*0.16, h*0.74)
      ..lineTo(w*0.22, h*0.58)
      ..close(), _fin);
    c.drawPath(Path()
      ..moveTo(w*0.80, h*0.38)
      ..quadraticBezierTo(w*1.0, h*0.62, w*0.84, h*0.74)
      ..lineTo(w*0.78, h*0.58)
      ..close(), _fin);
    c.drawCircle(Offset(w*0.63, h*0.27), w*0.07, _eye);
    c.drawCircle(Offset(w*0.65, h*0.24), w*0.023, _shine);
  }

  void _sword(Canvas c, Size s) {
    final w = s.width; final h = s.height;
    c.drawPath(Path()
      ..moveTo(w*0.78, h*0.5)
      ..lineTo(w*0.97, h*0.16)
      ..lineTo(w*0.97, h*0.84)
      ..close(), _fin);
    final body = Path()..addOval(Rect.fromCenter(center: Offset(w*0.52, h*0.5), width: w*0.56, height: h*0.44));
    c.drawPath(body, _body);
    c.drawPath(body, _outline);
    final bill = Path()
      ..moveTo(w*0.24, h*0.46)
      ..lineTo(w*0.0, h*0.5)
      ..lineTo(w*0.24, h*0.56)
      ..close();
    c.drawPath(bill, _fin);
    c.drawPath(bill, _outline);
    c.drawPath(Path()
      ..moveTo(w*0.36, h*0.28)
      ..quadraticBezierTo(w*0.54, h*0.13, w*0.70, h*0.28)
      ..lineTo(w*0.70, h*0.32)
      ..lineTo(w*0.36, h*0.32)
      ..close(), _fin);
    c.drawCircle(Offset(w*0.30, h*0.42), w*0.058, _eye);
    c.drawCircle(Offset(w*0.32, h*0.38), w*0.019, _shine);
  }

  void _ray(Canvas c, Size s) {
    final w = s.width; final h = s.height;
    c.drawPath(Path()
      ..moveTo(w*0.38, h*0.5)
      ..lineTo(w*0.08, h*0.28)
      ..lineTo(w*0.03, h*0.5)
      ..lineTo(w*0.08, h*0.72)
      ..close(), _fin);
    final body = Path()
      ..moveTo(w*0.5, h*0.06)
      ..lineTo(w*0.97, h*0.5)
      ..lineTo(w*0.5, h*0.94)
      ..lineTo(w*0.28, h*0.5)
      ..close();
    c.drawPath(body, _body);
    c.drawPath(body, _outline);
    c.drawLine(Offset(w*0.44, h*0.27), Offset(w*0.83, h*0.5), _scale);
    c.drawLine(Offset(w*0.44, h*0.73), Offset(w*0.83, h*0.5), _scale);
    c.drawLine(Offset(w*0.37, h*0.5), Offset(w*0.83, h*0.5), _scale);
    c.drawCircle(Offset(w*0.76, h*0.41), w*0.056, _eye);
    c.drawCircle(Offset(w*0.78, h*0.37), w*0.018, _shine);
  }

  void _arrow(Canvas c, Size s) {
    final w = s.width; final h = s.height;
    final body = Path()
      ..moveTo(w*0.98, h*0.5)
      ..lineTo(w*0.54, h*0.06)
      ..lineTo(w*0.54, h*0.30)
      ..lineTo(w*0.02, h*0.30)
      ..lineTo(w*0.02, h*0.70)
      ..lineTo(w*0.54, h*0.70)
      ..lineTo(w*0.54, h*0.94)
      ..close();
    c.drawPath(body, _body);
    c.drawPath(body, _outline);
    c.drawLine(Offset(w*0.18, h*0.30), Offset(w*0.18, h*0.70), _scale);
    c.drawLine(Offset(w*0.35, h*0.30), Offset(w*0.35, h*0.70), _scale);
    c.drawCircle(Offset(w*0.76, h*0.42), w*0.058, _eye);
    c.drawCircle(Offset(w*0.78, h*0.38), w*0.019, _shine);
  }

  @override
  bool shouldRepaint(FishPainter old) =>
      old.fishId != fishId || old.bodyColor != bodyColor;
}

class FishCard extends StatelessWidget {
  final int fishId;
  final double size;
  final bool correct;
  final bool wrong;
  final bool isDim;
  final VoidCallback? onTap;

  const FishCard({
    super.key,
    required this.fishId,
    this.size = 58,
    this.correct = false,
    this.wrong = false,
    this.isDim = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = const Color(0xFF252525);
    Color bgColor = const Color(0xFF161616);
    if (correct) { borderColor = const Color(0xFF2D6E4A); bgColor = const Color(0xFF0D1F14); }
    else if (wrong) { borderColor = const Color(0xFF6E2D2D); bgColor = const Color(0xFF1F0D0D); }

    return GestureDetector(
      onTap: isDim ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDim ? 0.18 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: size,
          height: size * 1.24,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          padding: const EdgeInsets.all(8),
          child: CustomPaint(painter: FishPainter(fishId: fishId)),
        ),
      ),
    );
  }
}
