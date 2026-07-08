import 'dart:math' as math;
import 'package:flutter/material.dart';

class BadgeIcon extends StatelessWidget {
  final int metaCartillas;
  final double size;
  final bool unlocked;

  const BadgeIcon({
    super.key,
    required this.metaCartillas,
    this.size = 68,
    this.unlocked = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BadgePainter(metaCartillas: metaCartillas, unlocked: unlocked),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  final int metaCartillas;
  final bool unlocked;

  _BadgePainter({required this.metaCartillas, required this.unlocked});

  int get _tier {
    if (metaCartillas <= 15) return 1;
    if (metaCartillas <= 30) return 2;
    if (metaCartillas <= 45) return 3;
    if (metaCartillas <= 70) return 4;
    return 5;
  }

  Color get _baseColor {
    if (!unlocked) return Colors.grey.shade400;
    switch (_tier) {
      case 1: return const Color(0xFFCD7F32);
      case 2: return const Color(0xFFA0A0A0);
      case 3: return const Color(0xFFFFD700);
      case 4: return const Color(0xFFB0C4DE);
      case 5: return const Color(0xFF4A90D9);
      default: return Colors.grey;
    }
  }

  Color get _accentColor {
    if (!unlocked) return Colors.grey.shade300;
    switch (_tier) {
      case 1: return const Color(0xFF8B4513);
      case 2: return const Color(0xFF808080);
      case 3: return const Color(0xFFDAA520);
      case 4: return const Color(0xFF708090);
      case 5: return const Color(0xFF2C5F8A);
      default: return Colors.grey;
    }
  }

  Color get _innerColor {
    if (!unlocked) return Colors.grey.shade100;
    switch (_tier) {
      case 1: return const Color(0xFFFFE4C4);
      case 2: return const Color(0xFFF0F0F0);
      case 3: return const Color(0xFFFFF8DC);
      case 4: return const Color(0xFFF0F8FF);
      case 5: return const Color(0xFFE8F4FD);
      default: return Colors.white;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.9;

    if (_tier == 1) {
      _drawBronze(canvas, cx, cy, r);
    } else if (_tier == 2) {
      _drawSilver(canvas, cx, cy, r);
    } else if (_tier == 3) {
      _drawGold(canvas, cx, cy, r);
    } else if (_tier == 4) {
      _drawPlatinum(canvas, cx, cy, r);
    } else {
      _drawDiamond(canvas, cx, cy, r);
    }

    _drawNumber(canvas, cx, cy, r);
  }

  void _drawBronze(Canvas canvas, double cx, double cy, double r) {
    final outer = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.3, cy - r * 0.7)
      ..lineTo(cx + r * 0.7, cy - r * 0.75)
      ..lineTo(cx + r * 0.6, cy - r * 0.25)
      ..lineTo(cx + r * 0.9, cy)
      ..lineTo(cx + r * 0.6, cy + r * 0.2)
      ..lineTo(cx + r * 0.65, cy + r * 0.55)
      ..lineTo(cx + r * 0.3, cy + r * 0.45)
      ..lineTo(cx, cy + r * 0.5)
      ..lineTo(cx - r * 0.3, cy + r * 0.45)
      ..lineTo(cx - r * 0.65, cy + r * 0.55)
      ..lineTo(cx - r * 0.6, cy + r * 0.2)
      ..lineTo(cx - r * 0.9, cy)
      ..lineTo(cx - r * 0.6, cy - r * 0.25)
      ..lineTo(cx - r * 0.7, cy - r * 0.75)
      ..lineTo(cx - r * 0.3, cy - r * 0.7)
      ..close();
    canvas.drawPath(outer, Paint()..color = _baseColor..style = PaintingStyle.fill);
    canvas.drawPath(outer, Paint()..color = _accentColor..style = PaintingStyle.stroke..strokeWidth = 2);

    canvas.drawCircle(Offset(cx, cy), r * 0.4, Paint()..color = _innerColor);
    canvas.drawCircle(Offset(cx, cy), r * 0.4, Paint()..color = _accentColor..style = PaintingStyle.stroke..strokeWidth = 1.5);

    if (unlocked) {
      final star = Path();
      for (int i = 0; i < 5; i++) {
        final angle = -math.pi / 2 + i * 2 * math.pi / 5;
        final x = cx + r * 0.3 * math.cos(angle);
        final y = cy - r * 0.3 + r * 0.3 * math.sin(angle);
        if (i == 0) {
          star.moveTo(x, y);
        } else {
          star.lineTo(x, y);
        }
      }
      star.close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill);
    }
  }

  void _drawSilver(Canvas canvas, double cx, double cy, double r) {
    canvas.drawCircle(Offset(cx, cy), r * 0.85, Paint()..color = _baseColor);
    canvas.drawCircle(Offset(cx, cy), r * 0.85, Paint()..color = _accentColor..style = PaintingStyle.stroke..strokeWidth = 2.5);

    final dashPaint = Paint()..color = const Color(0xFFE8E8E8)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for (double i = 0; i < 360; i += 12) {
      final a = i * math.pi / 180;
      final a2 = (i + 6) * math.pi / 180;
      final x1 = cx + r * 0.6 * math.cos(a);
      final y1 = cy + r * 0.6 * math.sin(a);
      final x2 = cx + r * 0.6 * math.cos(a2);
      final y2 = cy + r * 0.6 * math.sin(a2);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dashPaint);
    }

    canvas.drawCircle(Offset(cx, cy), r * 0.4, Paint()..color = _innerColor);
    canvas.drawCircle(Offset(cx, cy), r * 0.4, Paint()..color = _accentColor..style = PaintingStyle.stroke..strokeWidth = 2);

    if (unlocked) {
      for (int j = 0; j < 2; j++) {
        final yOff = cy + (j == 0 ? -r * 0.45 : r * 0.45);
        final star = Path();
        for (int i = 0; i < 5; i++) {
          final angle = -math.pi / 2 + i * 2 * math.pi / 5;
          final sx = cx + r * 0.2 * math.cos(angle);
          final sy = yOff + r * 0.2 * math.sin(angle);
          if (i == 0) {
            star.moveTo(sx, sy);
          } else {
            star.lineTo(sx, sy);
          }
        }
        star.close();
        canvas.drawPath(star, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill);
      }
    }
  }

  void _drawGold(Canvas canvas, double cx, double cy, double r) {
    final shield = Path()
      ..moveTo(cx, cy - r * 0.85)
      ..lineTo(cx + r * 0.5, cy - r * 0.5)
      ..lineTo(cx + r * 0.75, cy - r * 0.65)
      ..lineTo(cx + r * 0.7, cy - r * 0.2)
      ..lineTo(cx + r * 0.9, cy + r * 0.1)
      ..lineTo(cx + r * 0.65, cy + r * 0.35)
      ..lineTo(cx + r * 0.7, cy + r * 0.7)
      ..lineTo(cx + r * 0.35, cy + r * 0.6)
      ..lineTo(cx, cy + r * 0.8)
      ..lineTo(cx - r * 0.35, cy + r * 0.6)
      ..lineTo(cx - r * 0.7, cy + r * 0.7)
      ..lineTo(cx - r * 0.65, cy + r * 0.35)
      ..lineTo(cx - r * 0.9, cy + r * 0.1)
      ..lineTo(cx - r * 0.7, cy - r * 0.2)
      ..lineTo(cx - r * 0.75, cy - r * 0.65)
      ..lineTo(cx - r * 0.5, cy - r * 0.5)
      ..close();
    canvas.drawPath(shield, Paint()..color = _baseColor..style = PaintingStyle.fill);
    canvas.drawPath(shield, Paint()..color = _accentColor..style = PaintingStyle.stroke..strokeWidth = 2.5);

    final inner = Path()
      ..moveTo(cx, cy - r * 0.5)
      ..lineTo(cx + r * 0.3, cy - r * 0.25)
      ..lineTo(cx + r * 0.5, cy - r * 0.35)
      ..lineTo(cx + r * 0.4, cy - r * 0.05)
      ..lineTo(cx + r * 0.55, cy + r * 0.2)
      ..lineTo(cx + r * 0.35, cy + r * 0.35)
      ..lineTo(cx, cy + r * 0.45)
      ..lineTo(cx - r * 0.35, cy + r * 0.35)
      ..lineTo(cx - r * 0.55, cy + r * 0.2)
      ..lineTo(cx - r * 0.4, cy - r * 0.05)
      ..lineTo(cx - r * 0.5, cy - r * 0.35)
      ..lineTo(cx - r * 0.3, cy - r * 0.25)
      ..close();
    canvas.drawPath(inner, Paint()..color = _innerColor..style = PaintingStyle.fill);

    if (unlocked) {
      final star = Path();
      for (int i = 0; i < 5; i++) {
        final angle = -math.pi / 2 + i * 2 * math.pi / 5;
        final sx = cx + r * 0.18 * math.cos(angle);
        final sy = cy + r * 0.05 + r * 0.18 * math.sin(angle);
        if (i == 0) {
          star.moveTo(sx, sy);
        } else {
          star.lineTo(sx, sy);
        }
      }
      star.close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFFF6600)..style = PaintingStyle.fill);
    }
  }

  void _drawPlatinum(Canvas canvas, double cx, double cy, double r) {
    final polygon = Path();
    for (int i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 8;
      final rr = i.isEven ? r * 0.85 : r * 0.6;
      final x = cx + rr * math.cos(angle);
      final y = cy + rr * math.sin(angle);
      if (i == 0) {
        polygon.moveTo(x, y);
      } else {
        polygon.lineTo(x, y);
      }
    }
    polygon.close();
    canvas.drawPath(polygon, Paint()..color = _baseColor..style = PaintingStyle.fill);
    canvas.drawPath(polygon, Paint()..color = _accentColor..style = PaintingStyle.stroke..strokeWidth = 2.5);

    canvas.drawCircle(Offset(cx, cy), r * 0.5, Paint()..color = _innerColor);
    canvas.drawCircle(Offset(cx, cy), r * 0.5, Paint()..color = _accentColor..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(Offset(cx, cy), r * 0.38, Paint()..color = const Color(0xFFB0C4DE)..style = PaintingStyle.stroke..strokeWidth = 1);

    if (unlocked) {
      for (int j = 0; j < 3; j++) {
        final a = -math.pi / 2 + j * 2 * math.pi / 3;
        final sx = cx + r * 0.55 * math.cos(a);
        final sy = cy - r * 0.1 + r * 0.55 * math.sin(a);
        canvas.drawCircle(Offset(sx, sy), r * 0.1, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill);
      }
    }
  }

  void _drawDiamond(Canvas canvas, double cx, double cy, double r) {
    canvas.drawCircle(Offset(cx, cy), r * 0.88, Paint()..color = _baseColor);
    canvas.drawCircle(Offset(cx, cy), r * 0.88, Paint()..color = _accentColor..style = PaintingStyle.stroke..strokeWidth = 3);

    canvas.drawCircle(Offset(cx, cy), r * 0.7, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 2);

    canvas.drawCircle(Offset(cx, cy), r * 0.52, Paint()..color = _innerColor);
    canvas.drawCircle(Offset(cx, cy), r * 0.52, Paint()..color = _accentColor..style = PaintingStyle.stroke..strokeWidth = 2.5);
    canvas.drawCircle(Offset(cx, cy), r * 0.35, Paint()..color = const Color(0xFFB9F2FF)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    if (unlocked) {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy + r * 0.45), radius: r * 0.3),
          math.pi, math.pi, false, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 2.5);

      final star = Path();
      for (int i = 0; i < 5; i++) {
        final angle = -math.pi / 2 + i * 2 * math.pi / 5;
        final sx = cx + r * 0.22 * math.cos(angle);
        final sy = cy - r * 0.1 + r * 0.22 * math.sin(angle);
        if (i == 0) {
          star.moveTo(sx, sy);
        } else {
          star.lineTo(sx, sy);
        }
      }
      star.close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill);

      final star2 = Path();
      for (int i = 0; i < 5; i++) {
        final angle = -math.pi / 2 + i * 2 * math.pi / 5;
        final sx = cx + r * 0.12 * math.cos(angle);
        final sy = cy - r * 0.1 + r * 0.12 * math.sin(angle);
        if (i == 0) {
          star2.moveTo(sx, sy);
        } else {
          star2.lineTo(sx, sy);
        }
      }
      star2.close();
      canvas.drawPath(star2, Paint()..color = const Color(0xFFFFF8DC)..style = PaintingStyle.fill);
    }
  }

  void _drawNumber(Canvas canvas, double cx, double cy, double r) {
    final text = '$metaCartillas';
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: unlocked ? _accentColor : Colors.grey.shade500,
          fontSize: r * 0.4,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _BadgePainter oldDelegate) =>
      oldDelegate.metaCartillas != metaCartillas || oldDelegate.unlocked != unlocked;
}
