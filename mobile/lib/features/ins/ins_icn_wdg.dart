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

  Color get _pri => unlocked ? const Color(0xFF1D3F73) : Colors.grey.shade400;
  Color get _sec => unlocked ? const Color(0xFF00A6D6) : Colors.grey.shade300;
  Color get _acc => unlocked ? const Color(0xFFFFC400) : Colors.grey.shade300;
  Color get _gld => unlocked ? const Color(0xFFFFD700) : Colors.grey.shade300;
  Color get _brn => unlocked ? const Color(0xFFCD7F32) : Colors.grey.shade400;
  Color get _slv => unlocked ? const Color(0xFFA0A0A0) : Colors.grey.shade400;
  Color get _wht => unlocked ? Colors.white : Colors.grey.shade100;
  Color get _drk => unlocked ? Colors.black87 : Colors.grey.shade500;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.85;

    switch (metaCartillas) {
      case 5: _drawShield(canvas, cx, cy, r);
      case 10: _drawPen(canvas, cx, cy, r);
      case 15: _drawNotepad(canvas, cx, cy, r);
      case 20: _drawRadio(canvas, cx, cy, r);
      case 25: _drawCamera(canvas, cx, cy, r);
      case 30: _drawWhistle(canvas, cx, cy, r);
      case 35: _drawMagnifier(canvas, cx, cy, r);
      case 40: _drawCompass(canvas, cx, cy, r);
      case 45: _drawStarBadge(canvas, cx, cy, r);
      case 50: _drawSheriffStar(canvas, cx, cy, r);
      case 60: _drawBriefcase(canvas, cx, cy, r);
      case 70: _drawClipboard(canvas, cx, cy, r);
      case 80: _drawWatchtower(canvas, cx, cy, r);
      case 90: _drawScroll(canvas, cx, cy, r);
      case 100: _drawLaurel(canvas, cx, cy, r);
      case 110: _drawAgent(canvas, cx, cy, r);
      case 120: _drawPapamike(canvas, cx, cy, r);
      case 130: _drawCrazy(canvas, cx, cy, r);
      case 140: _drawShark(canvas, cx, cy, r);
      default: _drawShield(canvas, cx, cy, r);
    }
  }

  void _drawShield(Canvas c, double cx, double cy, double r) {
    final p = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.8, cy - r * 0.55)
      ..lineTo(cx + r * 0.8, cy + r * 0.3)
      ..cubicTo(cx + r * 0.8, cy + r * 0.65, cx, cy + r * 0.9, cx, cy + r * 0.9)
      ..cubicTo(cx, cy + r * 0.9, cx - r * 0.8, cy + r * 0.65, cx - r * 0.8, cy + r * 0.3)
      ..lineTo(cx - r * 0.8, cy - r * 0.55)
      ..close();
    c.drawPath(p, Paint()..color = _brn..style = PaintingStyle.fill);
    c.drawPath(p, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final inner = Path()
      ..moveTo(cx, cy - r * 0.65)
      ..lineTo(cx + r * 0.45, cy - r * 0.35)
      ..lineTo(cx + r * 0.45, cy + r * 0.2)
      ..cubicTo(cx + r * 0.45, cy + r * 0.45, cx, cy + r * 0.6, cx, cy + r * 0.6)
      ..cubicTo(cx, cy + r * 0.6, cx - r * 0.45, cy + r * 0.45, cx - r * 0.45, cy + r * 0.2)
      ..lineTo(cx - r * 0.45, cy - r * 0.35)
      ..close();
    c.drawPath(inner, Paint()..color = _wht..style = PaintingStyle.fill);
    _drawN(c, cx, cy, r * 0.6);
  }

  void _drawPen(Canvas c, double cx, double cy, double r) {
    final a = -math.pi / 4;
    final len = r * 0.9;
    final x1 = cx + len * math.cos(a);
    final y1 = cy + len * math.sin(a);
    final x2 = cx - len * math.cos(a);
    final y2 = cy - len * math.sin(a);
    c.drawLine(Offset(x1, y1), Offset(x2, y2), Paint()..color = _brn..strokeWidth = r * 0.4..strokeCap = StrokeCap.round);
    c.drawLine(Offset(x1, y1), Offset(x2, y2), Paint()..color = _wht..strokeWidth = r * 0.2);
    final tipX = cx + (r * 0.15) * math.cos(a + math.pi);
    final tipY = cy + (r * 0.15) * math.sin(a + math.pi);
    c.drawCircle(Offset(tipX, tipY), r * 0.08, Paint()..color = _drk);
    _drawN(c, cx, cy, r * 0.5);
  }

  void _drawNotepad(Canvas c, double cx, double cy, double r) {
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.3, height: r * 1.5);
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.08)), Paint()..color = _brn);
    c.drawRRect(RRect.fromRectAndRadius(rect.deflate(4), Radius.circular(r * 0.06)), Paint()..color = _wht..style = PaintingStyle.fill);
    c.drawRRect(RRect.fromRectAndRadius(rect.deflate(4), Radius.circular(r * 0.06)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final topBar = Rect.fromCenter(center: Offset(cx, cy - r * 0.6), width: r * 1.1, height: r * 0.12);
    c.drawRRect(RRect.fromRectAndRadius(topBar, Radius.circular(2)), Paint()..color = _drk);
    for (int i = 0; i < 4; i++) {
      final ly = cy - r * 0.35 + i * r * 0.25;
      c.drawLine(Offset(cx - r * 0.45, ly), Offset(cx + r * 0.45, ly), Paint()..color = _drk..strokeWidth = 1.5);
    }
    _drawN(c, cx, cy, r * 0.55);
  }

  void _drawRadio(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy + r * 0.05), width: r * 1.2, height: r * 0.7);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.1)), Paint()..color = _slv);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.1)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawRRect(RRect.fromRectAndRadius(body.deflate(4), Radius.circular(r * 0.08)), Paint()..color = _wht..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final speaker = Rect.fromCenter(center: Offset(cx + r * 0.4, cy + r * 0.05), width: r * 0.2, height: r * 0.4);
    c.drawRRect(RRect.fromRectAndRadius(speaker, Radius.circular(3)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int i = 0; i < 3; i++) {
      c.drawLine(Offset(cx + r * 0.4, cy - r * 0.12 + i * r * 0.12), Offset(cx + r * 0.4, cy - r * 0.06 + i * r * 0.12), Paint()..color = _drk..strokeWidth = 1.2);
    }
    c.drawLine(Offset(cx, cy - r * 0.3), Offset(cx, cy - r * 0.75), Paint()..color = _drk..strokeWidth = 2.5);
    c.drawLine(Offset(cx, cy - r * 0.75), Offset(cx + r * 0.3, cy - r * 0.85), Paint()..color = _drk..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy - r * 0.75), r * 0.04, Paint()..color = _acc);
    _drawN(c, cx, cy + r * 0.1, r * 0.45);
  }

  void _drawCamera(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.5, height: r * 0.95);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.08)), Paint()..color = _slv);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.08)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final top = Rect.fromCenter(center: Offset(cx + r * 0.1, cy - r * 0.38), width: r * 0.5, height: r * 0.15);
    c.drawRRect(RRect.fromRectAndRadius(top, Radius.circular(3)), Paint()..color = _drk);
    c.drawCircle(Offset(cx - r * 0.15, cy), r * 0.25, Paint()..color = _wht);
    c.drawCircle(Offset(cx - r * 0.15, cy), r * 0.25, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx - r * 0.15, cy), r * 0.12, Paint()..color = _drk);
    c.drawCircle(Offset(cx - r * 0.15, cy), r * 0.06, Paint()..color = _acc);
    c.drawCircle(Offset(cx + r * 0.45, cy - r * 0.2), r * 0.04, Paint()..color = _acc);
    _drawN(c, cx + r * 0.15, cy + r * 0.1, r * 0.35);
  }

  void _drawWhistle(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy), width: r * 0.7, height: r * 0.7);
    c.drawOval(body, Paint()..color = _slv);
    c.drawOval(body, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy), r * 0.2, Paint()..color = _wht..style = PaintingStyle.fill);
    c.drawCircle(Offset(cx, cy), r * 0.2, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final mouth = Path()
      ..moveTo(cx + r * 0.3, cy - r * 0.2)
      ..lineTo(cx + r * 0.8, cy - r * 0.35)
      ..lineTo(cx + r * 0.8, cy + r * 0.15)
      ..lineTo(cx + r * 0.3, cy + r * 0.2)
      ..close();
    c.drawPath(mouth, Paint()..color = _slv..style = PaintingStyle.fill);
    c.drawPath(mouth, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx + r * 0.65, cy), r * 0.04, Paint()..color = _drk);
    _drawN(c, cx, cy + r * 0.4, r * 0.4);
  }

  void _drawMagnifier(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx - r * 0.1, cy - r * 0.1), r * 0.45, Paint()..color = _gld);
    c.drawCircle(Offset(cx - r * 0.1, cy - r * 0.1), r * 0.45, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3);
    c.drawCircle(Offset(cx - r * 0.1, cy - r * 0.1), r * 0.33, Paint()..color = _acc);
    c.drawCircle(Offset(cx - r * 0.1, cy - r * 0.1), r * 0.33, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx - r * 0.1, cy - r * 0.1), r * 0.2, Paint()..color = _wht);
    final handle = Paint()..color = _drk..strokeWidth = r * 0.12..strokeCap = StrokeCap.round;
    c.drawLine(Offset(cx + r * 0.2, cy + r * 0.2), Offset(cx + r * 0.7, cy + r * 0.7), handle);
    c.drawLine(Offset(cx + r * 0.2, cy + r * 0.2), Offset(cx + r * 0.7, cy + r * 0.7), Paint()..color = _gld..strokeWidth = r * 0.06);
    _drawN(c, cx + r * 0.15, cy + r * 0.5, r * 0.35);
  }

  void _drawCompass(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.75, Paint()..color = _gld);
    c.drawCircle(Offset(cx, cy), r * 0.75, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawLine(Offset(cx, cy - r * 0.5), Offset(cx, cy + r * 0.5), Paint()..color = _drk..strokeWidth = 2);
    c.drawLine(Offset(cx - r * 0.5, cy), Offset(cx + r * 0.5, cy), Paint()..color = _drk..strokeWidth = 2);
    final triangle = Path()
      ..moveTo(cx, cy - r * 0.4)
      ..lineTo(cx - r * 0.12, cy + r * 0.05)
      ..lineTo(cx + r * 0.12, cy + r * 0.05)
      ..close();
    c.drawPath(triangle, Paint()..color = _acc);
    final triDown = Path()
      ..moveTo(cx, cy + r * 0.4)
      ..lineTo(cx - r * 0.12, cy - r * 0.05)
      ..lineTo(cx + r * 0.12, cy - r * 0.05)
      ..close();
    c.drawPath(triDown, Paint()..color = _drk);
    _drawN(c, cx, cy + r * 0.05, r * 0.35);
  }

  void _drawStarBadge(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.8, Paint()..color = _gld);
    c.drawCircle(Offset(cx, cy), r * 0.8, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.6, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), r * 0.6, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r * 0.5 : r * 0.22;
      final x = cx + rad * math.cos(a);
      final y = cy + rad * math.sin(a);
      if (i == 0) { star.moveTo(x, y); } else { star.lineTo(x, y); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _gld..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawN(c, cx, cy, r * 0.35);
  }

  void _drawSheriffStar(Canvas c, double cx, double cy, double r) {
    final star = Path();
    for (int i = 0; i < 12; i++) {
      final a = -math.pi / 2 + i * math.pi / 6;
      final rad = i.isEven ? r * 0.8 : r * 0.35;
      final x = cx + rad * math.cos(a);
      final y = cy + rad * math.sin(a);
      if (i == 0) { star.moveTo(x, y); } else { star.lineTo(x, y); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _gld..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.25, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy), r * 0.25, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    _drawN(c, cx, cy, r * 0.3);
  }

  void _drawBriefcase(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy + r * 0.05), width: r * 1.3, height: r * 0.85);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.06)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.06)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final handle = Rect.fromCenter(center: Offset(cx, cy - r * 0.38), width: r * 0.5, height: r * 0.2);
    c.drawRRect(RRect.fromRectAndRadius(handle, Radius.circular(r * 0.06)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(handle, Radius.circular(r * 0.06)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawLine(Offset(cx - r * 0.1, cy + r * 0.05), Offset(cx + r * 0.1, cy + r * 0.05), Paint()..color = _acc..strokeWidth = r * 0.06..strokeCap = StrokeCap.round);
    final lock = Rect.fromCenter(center: Offset(cx, cy + r * 0.05), width: r * 0.08, height: r * 0.12);
    c.drawOval(lock, Paint()..color = _gld..style = PaintingStyle.fill);
    c.drawOval(lock, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawN(c, cx, cy + r * 0.35, r * 0.35);
  }

  void _drawClipboard(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy + r * 0.08), width: r * 1.0, height: r * 1.2);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.05)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.05)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawRRect(RRect.fromRectAndRadius(body.deflate(4), Radius.circular(r * 0.04)), Paint()..color = _wht);
    final clip = Rect.fromCenter(center: Offset(cx, cy - r * 0.52), width: r * 0.2, height: r * 0.06);
    c.drawRRect(RRect.fromRectAndRadius(clip, Radius.circular(2)), Paint()..color = _slv);
    c.drawRRect(RRect.fromRectAndRadius(clip, Radius.circular(2)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int i = 0; i < 5; i++) {
      final ly = cy - r * 0.32 + i * r * 0.2;
      c.drawLine(Offset(cx - r * 0.35, ly), Offset(cx + r * 0.35, ly), Paint()..color = _drk..strokeWidth = 1.2);
    }
    final stamp = Rect.fromCenter(center: Offset(cx + r * 0.3, cy + r * 0.3), width: r * 0.18, height: r * 0.18);
    c.drawRRect(RRect.fromRectAndRadius(stamp, Radius.circular(2)), Paint()..color = _acc);
    _drawN(c, cx, cy + r * 0.08, r * 0.4);
  }

  void _drawWatchtower(Canvas c, double cx, double cy, double r) {
    final base = Rect.fromCenter(center: Offset(cx, cy + r * 0.2), width: r * 0.7, height: r * 0.7);
    c.drawRect(base, Paint()..color = _sec);
    c.drawRect(base, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final roof = Path()
      ..moveTo(cx - r * 0.5, cy - r * 0.3)
      ..lineTo(cx, cy - r * 0.85)
      ..lineTo(cx + r * 0.5, cy - r * 0.3)
      ..close();
    c.drawPath(roof, Paint()..color = _pri);
    c.drawPath(roof, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final window = Rect.fromCenter(center: Offset(cx, cy), width: r * 0.2, height: r * 0.25);
    c.drawRRect(RRect.fromRectAndRadius(window, Radius.circular(2)), Paint()..color = _acc);
    c.drawRRect(RRect.fromRectAndRadius(window, Radius.circular(2)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawLine(Offset(cx, cy - r * 0.12), Offset(cx, cy + r * 0.12), Paint()..color = _drk..strokeWidth = 1);
    _drawN(c, cx, cy + r * 0.55, r * 0.35);
  }

  void _drawScroll(Canvas c, double cx, double cy, double r) {
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.1, height: r * 1.3);
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.06)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.06)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawRRect(RRect.fromRectAndRadius(rect.deflate(4), Radius.circular(r * 0.04)), Paint()..color = const Color(0xFFFFF8E7));
    final topRoll = Rect.fromCenter(center: Offset(cx, cy - r * 0.55), width: r * 1.3, height: r * 0.15);
    c.drawRRect(RRect.fromRectAndRadius(topRoll, Radius.circular(r * 0.08)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(topRoll, Radius.circular(r * 0.08)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final botRoll = Rect.fromCenter(center: Offset(cx, cy + r * 0.55), width: r * 1.3, height: r * 0.15);
    c.drawRRect(RRect.fromRectAndRadius(botRoll, Radius.circular(r * 0.08)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(botRoll, Radius.circular(r * 0.08)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    for (int i = 0; i < 3; i++) {
      final ly = cy - r * 0.3 + i * r * 0.3;
      c.drawLine(Offset(cx - r * 0.4, ly), Offset(cx + r * 0.4, ly), Paint()..color = _drk..strokeWidth = 1.2);
    }
    c.drawCircle(Offset(cx, cy - r * 0.55), r * 0.06, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy + r * 0.55), r * 0.06, Paint()..color = _acc);
    _drawN(c, cx, cy, r * 0.4);
  }

  void _drawLaurel(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.82, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy), r * 0.82, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3);
    c.drawCircle(Offset(cx, cy), r * 0.65, Paint()..color = _gld..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.48, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), r * 0.48, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.35, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int i = 0; i < 14; i++) {
      final a = i * 2 * math.pi / 14;
      final leafIn = r * 0.55;
      final leafOut = r * 0.78;
      final lx1 = cx + leafIn * math.cos(a);
      final ly1 = cy + leafIn * math.sin(a);
      final lx2 = cx + leafOut * math.cos(a);
      final ly2 = cy + leafOut * math.sin(a);
      final midA = a + math.pi / 28;
      final midR = (leafIn + leafOut) / 2;
      final mx = cx + (midR + r * 0.04) * math.cos(midA);
      final my = cy + (midR + r * 0.04) * math.sin(midA);
      final leaf = Path()
        ..moveTo(lx1, ly1)
        ..quadraticBezierTo(mx, my, lx2, ly2)
        ..quadraticBezierTo(
          cx + (midR - r * 0.04) * math.cos(a - math.pi / 28),
          cy + (midR - r * 0.04) * math.sin(a - math.pi / 28),
          lx1, ly1);
      c.drawPath(leaf, Paint()..color = _gld..style = PaintingStyle.fill);
    }
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r * 0.28 : r * 0.12;
      final sx = cx + rad * math.cos(a);
      final sy = cy + rad * math.sin(a);
      if (i == 0) { star.moveTo(sx, sy); } else { star.lineTo(sx, sy); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _gld..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    _drawN(c, cx, cy, r * 0.3);
  }

  void _drawAgent(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy - r * 0.2), r * 0.28, Paint()..color = const Color(0xFFFFE0BD));
    c.drawCircle(Offset(cx, cy - r * 0.2), r * 0.28, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final body = Rect.fromCenter(center: Offset(cx, cy + r * 0.2), width: r * 0.9, height: r * 0.7);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.1)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.1)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final half = Rect.fromCenter(center: Offset(cx - r * 0.22, cy + r * 0.2), width: r * 0.45, height: r * 0.7);
    c.drawRRect(RRect.fromRectAndRadius(half, Radius.circular(r * 0.08)), Paint()..color = _sec);
    c.drawCircle(Offset(cx, cy - r * 0.2), r * 0.06, Paint()..color = _drk);
    c.drawLine(Offset(cx, cy - r * 0.05), Offset(cx, cy + r * 0.1), Paint()..color = _drk..strokeWidth = 1.5);
    final hat = Rect.fromCenter(center: Offset(cx, cy - r * 0.45), width: r * 0.5, height: r * 0.1);
    c.drawRRect(RRect.fromRectAndRadius(hat, Radius.circular(3)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(hat, Radius.circular(3)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawCircle(Offset(cx, cy - r * 0.48), r * 0.02, Paint()..color = _acc);
    c.drawCircle(Offset(cx - r * 0.2, cy + r * 0.15), r * 0.04, Paint()..color = _acc);
    _drawN(c, cx + r * 0.05, cy + r * 0.45, r * 0.4);
  }

  void _drawPapamike(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.7, Paint()..color = _gld);
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.7, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.52, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.52, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.35, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.35, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r * 0.25 : r * 0.1;
      final sx = cx + rad * math.cos(a);
      final sy = cy - r * 0.05 + rad * math.sin(a);
      if (i == 0) { star.moveTo(sx, sy); } else { star.lineTo(sx, sy); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _gld..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    final ribbon = Rect.fromCenter(center: Offset(cx, cy + r * 0.55), width: r * 0.3, height: r * 0.25);
    c.drawRRect(RRect.fromRectAndRadius(ribbon, Radius.circular(3)), Paint()..color = _acc);
    c.drawRRect(RRect.fromRectAndRadius(ribbon, Radius.circular(3)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawN(c, cx, cy - r * 0.05, r * 0.3);
  }

  void _drawCrazy(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy - r * 0.25), r * 0.3, Paint()..color = const Color(0xFFFFE0BD));
    c.drawCircle(Offset(cx, cy - r * 0.25), r * 0.3, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    for (int i = 0; i < 8; i++) {
      final a = i * 2 * math.pi / 8 - math.pi / 2;
      final sx = cx + r * 0.28 * math.cos(a);
      final sy = cy - r * 0.25 + r * 0.28 * math.sin(a);
      final ex = cx + r * 0.55 * math.cos(a);
      final ey = cy - r * 0.55 + r * 0.5 * math.sin(a);
      c.drawLine(Offset(sx, sy), Offset(ex, ey), Paint()..color = _drk..strokeWidth = 2.5..strokeCap = StrokeCap.round);
      c.drawCircle(Offset(ex, ey), r * 0.03, Paint()..color = _acc);
    }
    c.drawCircle(Offset(cx - r * 0.08, cy - r * 0.28), r * 0.04, Paint()..color = _drk);
    c.drawCircle(Offset(cx + r * 0.08, cy - r * 0.28), r * 0.04, Paint()..color = _drk);
    c.drawCircle(Offset(cx - r * 0.08, cy - r * 0.28), r * 0.015, Paint()..color = _wht);
    c.drawCircle(Offset(cx + r * 0.08, cy - r * 0.28), r * 0.015, Paint()..color = _wht);
    final mouth = Path()
      ..moveTo(cx - r * 0.1, cy - r * 0.08)
      ..lineTo(cx - r * 0.18, cy)
      ..lineTo(cx - r * 0.08, cy + r * 0.02)
      ..lineTo(cx, cy + r * 0.1)
      ..lineTo(cx + r * 0.08, cy + r * 0.02)
      ..lineTo(cx + r * 0.18, cy)
      ..lineTo(cx + r * 0.1, cy - r * 0.08)
      ..close();
    c.drawPath(mouth, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final clipboard = Rect.fromCenter(center: Offset(cx, cy + r * 0.4), width: r * 0.55, height: r * 0.5);
    c.drawRRect(RRect.fromRectAndRadius(clipboard, Radius.circular(4)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(clipboard, Radius.circular(4)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int i = 0; i < 3; i++) {
      c.drawLine(Offset(cx - r * 0.18, cy + r * 0.2 + i * r * 0.12), Offset(cx + r * 0.18, cy + r * 0.2 + i * r * 0.12), Paint()..color = _drk..strokeWidth = 1);
    }
    _drawN(c, cx, cy + r * 0.45, r * 0.25);
  }

  void _drawShark(Canvas c, double cx, double cy, double r) {
    final body = Path()
      ..moveTo(cx - r * 0.7, cy)
      ..cubicTo(cx - r * 0.7, cy - r * 0.5, cx + r * 0.5, cy - r * 0.55, cx + r * 0.7, cy - r * 0.25)
      ..lineTo(cx + r * 0.75, cy - r * 0.1)
      ..lineTo(cx + r * 0.9, cy - r * 0.1)
      ..lineTo(cx + r * 0.9, cy + r * 0.1)
      ..lineTo(cx + r * 0.75, cy + r * 0.1)
      ..lineTo(cx + r * 0.7, cy + r * 0.25)
      ..cubicTo(cx + r * 0.5, cy + r * 0.55, cx - r * 0.7, cy + r * 0.5, cx - r * 0.7, cy)
      ..close();
    c.drawPath(body, Paint()..color = _sec);
    c.drawPath(body, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final dorsal = Path()
      ..moveTo(cx + r * 0.15, cy - r * 0.45)
      ..lineTo(cx + r * 0.3, cy - r * 0.8)
      ..lineTo(cx + r * 0.45, cy - r * 0.45)
      ..close();
    c.drawPath(dorsal, Paint()..color = _pri);
    c.drawPath(dorsal, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final tail = Path()
      ..moveTo(cx - r * 0.7, cy)
      ..lineTo(cx - r * 0.85, cy - r * 0.3)
      ..lineTo(cx - r * 0.7, cy - r * 0.1)
      ..lineTo(cx - r * 0.85, cy + r * 0.3)
      ..close();
    c.drawPath(tail, Paint()..color = _pri);
    c.drawPath(tail, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx + r * 0.2, cy - r * 0.05), r * 0.05, Paint()..color = _drk);
    c.drawLine(Offset(cx + r * 0.35, cy - r * 0.15), Offset(cx + r * 0.35, cy + r * 0.05), Paint()..color = _drk..strokeWidth = 2.5);
    final belly = Path()
      ..moveTo(cx - r * 0.4, cy + r * 0.1)
      ..cubicTo(cx, cy + r * 0.35, cx + r * 0.4, cy + r * 0.2, cx + r * 0.5, cy + r * 0.05)
      ..cubicTo(cx + r * 0.3, cy + r * 0.25, cx - r * 0.2, cy + r * 0.2, cx - r * 0.4, cy + r * 0.1);
    c.drawPath(belly, Paint()..color = _wht);
    _drawN(c, cx - r * 0.05, cy + r * 0.15, r * 0.35);
  }

  void _drawN(Canvas c, double cx, double cy, double s) {
    final t = '$metaCartillas';
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          color: _drk,
          fontSize: s * 0.6,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(c, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BadgePainter oldDelegate) =>
      oldDelegate.metaCartillas != metaCartillas || oldDelegate.unlocked != unlocked;
}
