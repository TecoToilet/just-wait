// widgets/hook_animation.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

enum HookState { idle, descending, holding, ascending, snapping }

class HookWidget extends StatelessWidget {
  final double topOffset; // 0.0 = off screen top, 1.0 = center of screen
  final bool broken; // snapped on fail

  const HookWidget({
    super.key,
    required this.topOffset,
    this.broken = false,
  });

  @override
  Widget build(BuildContext context) {
    final lineLength = 60.0 + topOffset * 40;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // fishing line
        Container(
          width: 1.0,
          height: lineLength,
          color: broken ? const Color(0xFF3A3A3A) : const Color(0xFF555555),
        ),
        // hook SVG drawn with CustomPaint
        CustomPaint(
          size: const Size(24, 32),
          painter: _HookPainter(broken: broken),
        ),
      ],
    );
  }
}

class _HookPainter extends CustomPainter {
  final bool broken;
  const _HookPainter({this.broken = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final paint = Paint()
      ..color = broken ? const Color(0xFF3A3A3A) : const Color(0xFF666666)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    if (broken) {
      // broken hook - two disconnected pieces
      canvas.drawLine(Offset(w*0.5, 0), Offset(w*0.5, h*0.35), paint);
      canvas.drawLine(Offset(w*0.5, h*0.45), Offset(w*0.5, h*0.65), paint);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w*0.65, h*0.65), width: w*0.6, height: h*0.5),
        math.pi, math.pi * 0.8, false, paint,
      );
    } else {
      // normal hook
      canvas.drawLine(Offset(w*0.5, 0), Offset(w*0.5, h*0.55), paint);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w*0.65, h*0.6), width: w*0.6, height: h*0.55),
        math.pi, math.pi * 0.85, false, paint,
      );
      // barb
      final barb = Path()
        ..moveTo(w*0.92, h*0.72)
        ..lineTo(w*0.72, h*0.60)
        ..lineTo(w*0.88, h*0.56);
      canvas.drawPath(barb, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(_HookPainter old) => old.broken != broken;
}
