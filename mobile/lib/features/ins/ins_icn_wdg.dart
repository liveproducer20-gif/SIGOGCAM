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
      case 20: _drawNotepad(canvas, cx, cy, r);
      case 30: _drawRadio(canvas, cx, cy, r);
      case 45: _drawCamera(canvas, cx, cy, r);
      case 60: _drawWhistle(canvas, cx, cy, r);
      case 75: _drawMagnifier(canvas, cx, cy, r);
      case 95: _drawCompass(canvas, cx, cy, r);
      case 115: _drawStarBadge(canvas, cx, cy, r);
      case 135: _drawSheriffStar(canvas, cx, cy, r);
      case 155: _drawBriefcase(canvas, cx, cy, r);
      case 175: _drawClipboard(canvas, cx, cy, r);
      case 195: _drawWatchtower(canvas, cx, cy, r);
      case 215: _drawScroll(canvas, cx, cy, r);
      case 235: _drawLaurel(canvas, cx, cy, r);
      case 255: _drawAgent(canvas, cx, cy, r);
      case 275: _drawPapamike(canvas, cx, cy, r);
      case 295: _drawCrazy(canvas, cx, cy, r);
      case 315: _drawShark(canvas, cx, cy, r);
      case 335: _drawSniper(canvas, cx, cy, r);
      case 355: _drawTarget(canvas, cx, cy, r);
      case 375: _drawForensic(canvas, cx, cy, r);
      case 395: _drawEpaulettes(canvas, cx, cy, r);
      case 415: _drawRain(canvas, cx, cy, r);
      case 435: _drawFlying(canvas, cx, cy, r);
      case 455: _drawSuperhero(canvas, cx, cy, r);
      case 475: _drawShadow(canvas, cx, cy, r);
      case 500: _drawCommand(canvas, cx, cy, r);
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
    c.drawLine(Offset(cx, cy - r * 0.5), Offset(cx, cy + r * 0.4), Paint()..color = _drk..strokeWidth = 2);
    c.drawLine(Offset(cx - r * 0.4, cy - r * 0.05), Offset(cx + r * 0.4, cy - r * 0.05), Paint()..color = _drk..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy + r * 0.05), r * 0.18, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy + r * 0.05), r * 0.18, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawN(c, cx, cy, r * 0.6);
  }

  void _drawPen(Canvas c, double cx, double cy, double r) {
    final a = math.pi / 4;
    final len = r * 0.85;
    final x1 = cx + len * math.cos(a);
    final y1 = cy - len * math.sin(a);
    final x2 = cx - len * math.cos(a);
    final y2 = cy + len * math.sin(a);
    c.drawLine(Offset(x1, y1), Offset(x2, y2), Paint()..color = _brn..strokeWidth = r * 0.45..strokeCap = StrokeCap.round);
    c.drawLine(Offset(x1, y1), Offset(x2, y2), Paint()..color = _wht..strokeWidth = r * 0.2..strokeCap = StrokeCap.round);
    final nib = Path()
      ..moveTo(cx - r * 0.6, cy + r * 0.6)
      ..lineTo(cx - r * 0.75, cy + r * 0.7)
      ..lineTo(cx - r * 0.55, cy + r * 0.75)
      ..close();
    c.drawPath(nib, Paint()..color = _drk..style = PaintingStyle.fill);
    c.drawCircle(Offset(cx - r * 0.3, cy + r * 0.45), r * 0.08, Paint()..color = _acc);
    _drawN(c, cx + r * 0.05, cy - r * 0.05, r * 0.45);
  }

  void _drawNotepad(Canvas c, double cx, double cy, double r) {
    final tab = Path()
      ..moveTo(cx - r * 0.45, cy - r * 0.75)
      ..lineTo(cx - r * 0.1, cy - r * 0.75)
      ..lineTo(cx + r * 0.1, cy - r * 0.95)
      ..lineTo(cx + r * 0.45, cy - r * 0.95)
      ..lineTo(cx + r * 0.45, cy + r * 0.75)
      ..lineTo(cx - r * 0.45, cy + r * 0.75)
      ..close();
    c.drawPath(tab, Paint()..color = _pri);
    c.drawPath(tab, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final paper = Rect.fromCenter(center: Offset(cx, cy + r * 0.05), width: r * 1.1, height: r * 1.2);
    c.drawRRect(RRect.fromRectAndRadius(paper.deflate(8), Radius.circular(r * 0.04)), Paint()..color = _wht);
    for (int i = 0; i < 4; i++) {
      final ly = cy - r * 0.35 + i * r * 0.22;
      c.drawLine(Offset(cx - r * 0.4, ly), Offset(cx + r * 0.4, ly), Paint()..color = _drk..strokeWidth = 1.5);
    }
    final stamp = Rect.fromCenter(center: Offset(cx + r * 0.35, cy + r * 0.35), width: r * 0.16, height: r * 0.16);
    c.drawRRect(RRect.fromRectAndRadius(stamp, Radius.circular(3)), Paint()..color = _acc);
    c.drawRRect(RRect.fromRectAndRadius(stamp, Radius.circular(3)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    _drawN(c, cx, cy, r * 0.45);
  }

  void _drawRadio(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy + r * 0.05), width: r * 1.15, height: r * 0.7);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.1)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.1)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final screen = Rect.fromCenter(center: Offset(cx - r * 0.15, cy + r * 0.05), width: r * 0.4, height: r * 0.35);
    c.drawRRect(RRect.fromRectAndRadius(screen, Radius.circular(4)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(screen, Radius.circular(4)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final speaker = Rect.fromCenter(center: Offset(cx + r * 0.35, cy + r * 0.05), width: r * 0.2, height: r * 0.4);
    c.drawRRect(RRect.fromRectAndRadius(speaker, Radius.circular(3)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int i = 0; i < 3; i++) {
      c.drawLine(Offset(cx + r * 0.35, cy - r * 0.12 + i * r * 0.12), Offset(cx + r * 0.35, cy - r * 0.06 + i * r * 0.12), Paint()..color = _drk..strokeWidth = 1.5);
    }
    c.drawLine(Offset(cx, cy - r * 0.3), Offset(cx, cy - r * 0.7), Paint()..color = _drk..strokeWidth = 3);
    c.drawLine(Offset(cx, cy - r * 0.7), Offset(cx + r * 0.25, cy - r * 0.82), Paint()..color = _drk..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy - r * 0.7), r * 0.05, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy - r * 0.7), r * 0.05, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    _drawN(c, cx, cy + r * 0.4, r * 0.4);
  }

  void _drawCamera(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.4, height: r * 0.95);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.08)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.08)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final top = Rect.fromCenter(center: Offset(cx + r * 0.15, cy - r * 0.4), width: r * 0.4, height: r * 0.18);
    c.drawRRect(RRect.fromRectAndRadius(top, Radius.circular(4)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(top, Radius.circular(4)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final lens = Rect.fromCenter(center: Offset(cx - r * 0.1, cy), width: r * 0.52, height: r * 0.52);
    c.drawOval(lens, Paint()..color = _wht);
    c.drawOval(lens, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx - r * 0.1, cy), r * 0.14, Paint()..color = _drk);
    c.drawCircle(Offset(cx - r * 0.1, cy), r * 0.07, Paint()..color = _acc);
    c.drawCircle(Offset(cx + r * 0.45, cy - r * 0.3), r * 0.035, Paint()..color = _acc);
    final stripe = Rect.fromCenter(center: Offset(cx - r * 0.7, cy), width: r * 0.08, height: r * 0.12);
    c.drawRRect(RRect.fromRectAndRadius(stripe, Radius.circular(2)), Paint()..color = _sec);
    _drawN(c, cx + r * 0.2, cy + r * 0.25, r * 0.35);
  }

  void _drawWhistle(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy + r * 0.05), r * 0.38, Paint()..color = _slv);
    c.drawCircle(Offset(cx, cy + r * 0.05), r * 0.38, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy + r * 0.05), r * 0.16, Paint()..color = _drk..style = PaintingStyle.fill);
    final mouth = Path()
      ..moveTo(cx + r * 0.35, cy - r * 0.2)
      ..lineTo(cx + r * 0.85, cy - r * 0.35)
      ..lineTo(cx + r * 0.8, cy + r * 0.2)
      ..lineTo(cx + r * 0.35, cy + r * 0.25)
      ..close();
    c.drawPath(mouth, Paint()..color = _slv..style = PaintingStyle.fill);
    c.drawPath(mouth, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx + r * 0.7, cy), r * 0.035, Paint()..color = _drk);
    c.drawLine(Offset(cx, cy - r * 0.3), Offset(cx, cy - r * 0.65), Paint()..color = _drk..strokeWidth = 2.5);
    c.drawLine(Offset(cx, cy - r * 0.65), Offset(cx + r * 0.15, cy - r * 0.75), Paint()..color = _drk..strokeWidth = 2);
    c.drawCircle(Offset(cx + r * 0.15, cy - r * 0.75), r * 0.04, Paint()..color = _acc);
    _drawN(c, cx + r * 0.15, cy + r * 0.5, r * 0.35);
  }

  void _drawMagnifier(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx - r * 0.1, cy - r * 0.15), width: r * 0.9, height: r * 0.9);
    c.drawOval(body, Paint()..color = _gld);
    c.drawOval(body, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3);
    final inner = Rect.fromCenter(center: Offset(cx - r * 0.1, cy - r * 0.15), width: r * 0.6, height: r * 0.6);
    c.drawOval(inner, Paint()..color = _wht);
    c.drawOval(inner, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawLine(Offset(cx - r * 0.1, cy - r * 0.4), Offset(cx - r * 0.1, cy + r * 0.1), Paint()..color = _drk..strokeWidth = 1.5);
    c.drawLine(Offset(cx - r * 0.35, cy - r * 0.15), Offset(cx + r * 0.15, cy - r * 0.15), Paint()..color = _drk..strokeWidth = 1.5);
    c.drawLine(Offset(cx + r * 0.2, cy + r * 0.2), Offset(cx + r * 0.7, cy + r * 0.7), Paint()..color = _drk..strokeWidth = r * 0.12..strokeCap = StrokeCap.round);
    c.drawLine(Offset(cx + r * 0.2, cy + r * 0.2), Offset(cx + r * 0.7, cy + r * 0.7), Paint()..color = _gld..strokeWidth = r * 0.06..strokeCap = StrokeCap.round);
    c.drawCircle(Offset(cx - r * 0.1, cy - r * 0.15), r * 0.06, Paint()..color = _acc);
    _drawN(c, cx + r * 0.15, cy + r * 0.5, r * 0.35);
  }

  void _drawCompass(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.75, Paint()..color = _gld);
    c.drawCircle(Offset(cx, cy), r * 0.75, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawLine(Offset(cx, cy - r * 0.5), Offset(cx, cy + r * 0.5), Paint()..color = _drk..strokeWidth = 2.5);
    c.drawLine(Offset(cx - r * 0.5, cy), Offset(cx + r * 0.5, cy), Paint()..color = _drk..strokeWidth = 2.5);
    final triN = Path()
      ..moveTo(cx, cy - r * 0.4)
      ..lineTo(cx - r * 0.12, cy + r * 0.03)
      ..lineTo(cx + r * 0.12, cy + r * 0.03)
      ..close();
    c.drawPath(triN, Paint()..color = _acc);
    c.drawPath(triN, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    final triS = Path()
      ..moveTo(cx, cy + r * 0.4)
      ..lineTo(cx - r * 0.12, cy - r * 0.03)
      ..lineTo(cx + r * 0.12, cy - r * 0.03)
      ..close();
    c.drawPath(triS, Paint()..color = _drk);
    final triE = Path()
      ..moveTo(cx + r * 0.4, cy)
      ..lineTo(cx - r * 0.03, cy - r * 0.12)
      ..lineTo(cx - r * 0.03, cy + r * 0.12)
      ..close();
    c.drawPath(triE, Paint()..color = _acc);
    c.drawPath(triE, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    final triW = Path()
      ..moveTo(cx - r * 0.4, cy)
      ..lineTo(cx + r * 0.03, cy - r * 0.12)
      ..lineTo(cx + r * 0.03, cy + r * 0.12)
      ..close();
    c.drawPath(triW, Paint()..color = _drk);
    _drawN(c, cx, cy + r * 0.05, r * 0.3);
  }

  void _drawStarBadge(Canvas c, double cx, double cy, double r) {
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r * 0.8 : r * 0.35;
      final x = cx + rad * math.cos(a);
      final y = cy + rad * math.sin(a);
      if (i == 0) { star.moveTo(x, y); } else { star.lineTo(x, y); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _gld..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.35, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), r * 0.35, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.18, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy), r * 0.18, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawCircle(Offset(cx, cy), r * 0.07, Paint()..color = _acc);
    _drawN(c, cx, cy, r * 0.3);
  }

  void _drawSheriffStar(Canvas c, double cx, double cy, double r) {
    final star = Path();
    for (int i = 0; i < 18; i++) {
      final a = -math.pi / 2 + i * math.pi / 9;
      final rad = i.isEven ? r * 0.85 : r * 0.35;
      final x = cx + rad * math.cos(a);
      final y = cy + rad * math.sin(a);
      if (i == 0) { star.moveTo(x, y); } else { star.lineTo(x, y); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _gld..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.3, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy), r * 0.3, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy), r * 0.14, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy), r * 0.14, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawN(c, cx, cy, r * 0.3);
  }

  void _drawBriefcase(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy + r * 0.08), width: r * 1.3, height: r * 0.95);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.07)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.07)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final handle = Path()
      ..moveTo(cx - r * 0.35, cy - r * 0.35)
      ..lineTo(cx - r * 0.35, cy - r * 0.55)
      ..cubicTo(cx - r * 0.35, cy - r * 0.7, cx + r * 0.35, cy - r * 0.7, cx + r * 0.35, cy - r * 0.55)
      ..lineTo(cx + r * 0.35, cy - r * 0.35);
    c.drawPath(handle, Paint()..color = _pri..style = PaintingStyle.fill..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawPath(handle, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final panel = Rect.fromCenter(center: Offset(cx, cy + r * 0.08), width: r * 0.8, height: r * 0.75);
    c.drawRRect(RRect.fromRectAndRadius(panel, Radius.circular(r * 0.05)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(panel, Radius.circular(r * 0.05)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy + r * 0.2), r * 0.16, Paint()..color = _sec);
    c.drawCircle(Offset(cx, cy + r * 0.2), r * 0.16, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawCircle(Offset(cx, cy + r * 0.2), r * 0.06, Paint()..color = _acc);
    c.drawLine(Offset(cx - r * 0.25, cy - r * 0.1), Offset(cx + r * 0.25, cy - r * 0.1), Paint()..color = _drk..strokeWidth = 1.5);
    _drawN(c, cx, cy + r * 0.55, r * 0.35);
  }

  void _drawClipboard(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy + r * 0.1), width: r * 1.05, height: r * 1.3);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.06)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.06)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawRRect(RRect.fromRectAndRadius(body.deflate(5), Radius.circular(r * 0.04)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(body.deflate(5), Radius.circular(r * 0.04)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final clip = Rect.fromCenter(center: Offset(cx, cy - r * 0.55), width: r * 0.25, height: r * 0.12);
    c.drawRRect(RRect.fromRectAndRadius(clip, Radius.circular(3)), Paint()..color = _slv);
    c.drawRRect(RRect.fromRectAndRadius(clip, Radius.circular(3)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    for (int i = 0; i < 5; i++) {
      final ly = cy - r * 0.32 + i * r * 0.22;
      c.drawLine(Offset(cx - r * 0.38, ly), Offset(cx + r * 0.38, ly), Paint()..color = _drk..strokeWidth = 1.5);
    }
    final stamp = Rect.fromCenter(center: Offset(cx + r * 0.35, cy + r * 0.38), width: r * 0.2, height: r * 0.2);
    c.drawRRect(RRect.fromRectAndRadius(stamp, Radius.circular(3)), Paint()..color = _acc);
    c.drawRRect(RRect.fromRectAndRadius(stamp, Radius.circular(3)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawN(c, cx, cy + r * 0.1, r * 0.4);
  }

  void _drawWatchtower(Canvas c, double cx, double cy, double r) {
    final pillar = Rect.fromCenter(center: Offset(cx, cy + r * 0.15), width: r * 0.35, height: r * 0.85);
    c.drawRRect(RRect.fromRectAndRadius(pillar, Radius.circular(r * 0.05)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(pillar, Radius.circular(r * 0.05)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final lantern = Path()
      ..moveTo(cx - r * 0.5, cy - r * 0.25)
      ..lineTo(cx, cy - r * 0.85)
      ..lineTo(cx + r * 0.5, cy - r * 0.25)
      ..close();
    c.drawPath(lantern, Paint()..color = _acc);
    c.drawPath(lantern, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final glow = Path()
      ..moveTo(cx - r * 0.3, cy - r * 0.15)
      ..lineTo(cx, cy + r * 0.2)
      ..lineTo(cx + r * 0.3, cy - r * 0.15)
      ..close();
    c.drawPath(glow, Paint()..color = _wht..style = PaintingStyle.fill);
    final beamL = Path()
      ..moveTo(cx - r * 0.1, cy - r * 0.15)
      ..lineTo(cx - r * 0.8, cy + r * 0.6)
      ..lineTo(cx - r * 0.2, cy + r * 0.1);
    c.drawPath(beamL, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 2);
    final beamR = Path()
      ..moveTo(cx + r * 0.1, cy - r * 0.15)
      ..lineTo(cx + r * 0.8, cy + r * 0.6)
      ..lineTo(cx + r * 0.2, cy + r * 0.1);
    c.drawPath(beamR, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 2);
    _drawN(c, cx, cy + r * 0.5, r * 0.35);
  }

  void _drawScroll(Canvas c, double cx, double cy, double r) {
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.2, height: r * 1.0);
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.06)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.06)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final inner = Rect.fromCenter(center: Offset(cx, cy), width: r * 0.95, height: r * 0.75);
    c.drawRRect(RRect.fromRectAndRadius(inner, Radius.circular(r * 0.04)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(inner, Radius.circular(r * 0.04)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int i = 0; i < 3; i++) {
      final ly = cy - r * 0.2 + i * r * 0.22;
      c.drawLine(Offset(cx - r * 0.35, ly), Offset(cx + r * 0.35, ly), Paint()..color = _drk..strokeWidth = 1.2);
    }
    final seal = Rect.fromCenter(center: Offset(cx + r * 0.3, cy + r * 0.3), width: r * 0.2, height: r * 0.2);
    c.drawOval(seal, Paint()..color = _acc);
    c.drawOval(seal, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final ribbonL = Path()
      ..moveTo(cx - r * 0.6, cy - r * 0.6)
      ..lineTo(cx - r * 0.6, cy - r * 0.45)
      ..lineTo(cx - r * 0.45, cy - r * 0.5);
    c.drawPath(ribbonL, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 3);
    final ribbonR = Path()
      ..moveTo(cx + r * 0.6, cy - r * 0.6)
      ..lineTo(cx + r * 0.6, cy - r * 0.45)
      ..lineTo(cx + r * 0.45, cy - r * 0.5);
    c.drawPath(ribbonR, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 3);
    _drawN(c, cx, cy + r * 0.5, r * 0.4);
  }

  void _drawLaurel(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.82, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy), r * 0.82, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3);
    c.drawCircle(Offset(cx, cy), r * 0.65, Paint()..color = _gld..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.48, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), r * 0.48, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r * 0.35 : r * 0.14;
      final sx = cx + rad * math.cos(a);
      final sy = cy + rad * math.sin(a);
      if (i == 0) { star.moveTo(sx, sy); } else { star.lineTo(sx, sy); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _gld..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int i = 0; i < 16; i++) {
      final a = i * 2 * math.pi / 16;
      final dotX = cx + r * 0.75 * math.cos(a);
      final dotY = cy + r * 0.75 * math.sin(a);
      c.drawCircle(Offset(dotX, dotY), r * 0.04, Paint()..color = _gld);
    }
    _drawN(c, cx, cy, r * 0.3);
  }

  void _drawAgent(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy + r * 0.15), width: r * 1.0, height: r * 0.75);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.1)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.1)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final stripe = Rect.fromCenter(center: Offset(cx, cy + r * 0.15), width: r * 0.5, height: r * 0.75);
    c.drawRRect(RRect.fromRectAndRadius(stripe, Radius.circular(r * 0.08)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(stripe, Radius.circular(r * 0.08)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r * 0.12 : r * 0.05;
      final sx = cx + rad * math.cos(a);
      final sy = cy + r * 0.15 + rad * math.sin(a);
      if (i == 0) { star.moveTo(sx, sy); } else { star.lineTo(sx, sy); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    final badge = Rect.fromCenter(center: Offset(cx + r * 0.35, cy - r * 0.05), width: r * 0.15, height: r * 0.2);
    c.drawRRect(RRect.fromRectAndRadius(badge, Radius.circular(3)), Paint()..color = _acc);
    c.drawRRect(RRect.fromRectAndRadius(badge, Radius.circular(3)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    _drawN(c, cx, cy + r * 0.5, r * 0.4);
  }

  void _drawPapamike(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.65, Paint()..color = _gld);
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.65, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.48, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.48, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.3, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.3, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r * 0.2 : r * 0.08;
      final sx = cx + rad * math.cos(a);
      final sy = cy - r * 0.05 + rad * math.sin(a);
      if (i == 0) { star.moveTo(sx, sy); } else { star.lineTo(sx, sy); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _gld..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    final ribbon = Path()
      ..moveTo(cx - r * 0.35, cy + r * 0.45)
      ..lineTo(cx, cy + r * 0.7)
      ..lineTo(cx + r * 0.35, cy + r * 0.45)
      ..lineTo(cx + r * 0.4, cy + r * 0.55)
      ..lineTo(cx, cy + r * 0.8)
      ..lineTo(cx - r * 0.4, cy + r * 0.55)
      ..close();
    c.drawPath(ribbon, Paint()..color = _pri);
    c.drawPath(ribbon, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawN(c, cx, cy - r * 0.05, r * 0.25);
  }

  void _drawCrazy(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.75, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy), r * 0.75, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3);
    for (int i = 0; i < 12; i++) {
      final a = i * 2 * math.pi / 12 - math.pi / 2;
      final innerR = r * 0.6;
      final outerR = r * 0.85;
      final sx = cx + innerR * math.cos(a);
      final sy = cy + innerR * math.sin(a);
      final ex = cx + outerR * math.cos(a);
      final ey = cy + outerR * math.sin(a);
      c.drawLine(Offset(sx, sy), Offset(ex, ey), Paint()..color = _sec..strokeWidth = 2.5..strokeCap = StrokeCap.round);
      c.drawCircle(Offset(ex, ey), r * 0.035, Paint()..color = _acc);
    }
    c.drawCircle(Offset(cx, cy), r * 0.35, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), r * 0.35, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.15, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy), r * 0.15, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawN(c, cx, cy, r * 0.35);
  }

  void _drawShark(Canvas c, double cx, double cy, double r) {
    final outer = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 1.5, height: r * 1.3));
    c.drawPath(outer, Paint()..color = _sec);
    c.drawPath(outer, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3);
    final inner = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 1.0, height: r * 0.85));
    c.drawPath(inner, Paint()..color = _wht);
    c.drawPath(inner, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final pupil = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + r * 0.35, cy - r * 0.25)
      ..lineTo(cx + r * 0.35, cy + r * 0.25)
      ..close();
    c.drawPath(pupil, Paint()..color = _pri);
    c.drawPath(pupil, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawCircle(Offset(cx + r * 0.15, cy), r * 0.05, Paint()..color = _acc);
    _drawN(c, cx, cy + r * 0.1, r * 0.35);
  }

  void _drawSniper(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.78, Paint()..color = _sec);
    c.drawCircle(Offset(cx, cy), r * 0.78, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3);
    c.drawCircle(Offset(cx, cy), r * 0.58, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), r * 0.58, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.38, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy), r * 0.38, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy), r * 0.18, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy), r * 0.18, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawCircle(Offset(cx, cy), r * 0.06, Paint()..color = _acc);
    c.drawLine(Offset(cx - r * 0.82, cy), Offset(cx + r * 0.82, cy), Paint()..color = _drk..strokeWidth = 2);
    c.drawLine(Offset(cx, cy - r * 0.82), Offset(cx, cy + r * 0.82), Paint()..color = _drk..strokeWidth = 2);
    _drawN(c, cx, cy, r * 0.25);
  }

  void _drawTarget(Canvas c, double cx, double cy, double r) {
    final bowl = Path()
      ..moveTo(cx - r * 0.55, cy + r * 0.3)
      ..cubicTo(cx - r * 0.55, cy - r * 0.35, cx + r * 0.55, cy - r * 0.35, cx + r * 0.55, cy + r * 0.3)
      ..cubicTo(cx + r * 0.55, cy + r * 0.55, cx, cy + r * 0.6, cx, cy + r * 0.6)
      ..cubicTo(cx, cy + r * 0.6, cx - r * 0.55, cy + r * 0.55, cx - r * 0.55, cy + r * 0.3)
      ..close();
    c.drawPath(bowl, Paint()..color = _pri);
    c.drawPath(bowl, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final stem = Rect.fromCenter(center: Offset(cx, cy + r * 0.6), width: r * 0.1, height: r * 0.2);
    c.drawRect(stem, Paint()..color = _pri);
    c.drawRect(stem, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final base = Rect.fromCenter(center: Offset(cx, cy + r * 0.8), width: r * 0.5, height: r * 0.08);
    c.drawRRect(RRect.fromRectAndRadius(base, Radius.circular(3)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(base, Radius.circular(3)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final handleL = Path()
      ..moveTo(cx - r * 0.55, cy + r * 0.15)
      ..cubicTo(cx - r * 0.85, cy + r * 0.15, cx - r * 0.85, cy + r * 0.5, cx - r * 0.55, cy + r * 0.45);
    c.drawPath(handleL, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final handleR = Path()
      ..moveTo(cx + r * 0.55, cy + r * 0.15)
      ..cubicTo(cx + r * 0.85, cy + r * 0.15, cx + r * 0.85, cy + r * 0.5, cx + r * 0.55, cy + r * 0.45);
    c.drawPath(handleR, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy + r * 0.12), r * 0.16, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy + r * 0.12), r * 0.16, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawCircle(Offset(cx, cy + r * 0.12), r * 0.06, Paint()..color = _drk);
    _drawN(c, cx, cy + r * 0.35, r * 0.3);
  }

  void _drawForensic(Canvas c, double cx, double cy, double r) {
    final gem = Path()
      ..moveTo(cx, cy - r * 0.8)
      ..lineTo(cx + r * 0.5, cy - r * 0.25)
      ..lineTo(cx + r * 0.6, cy + r * 0.3)
      ..lineTo(cx, cy + r * 0.85)
      ..lineTo(cx - r * 0.6, cy + r * 0.3)
      ..lineTo(cx - r * 0.5, cy - r * 0.25)
      ..close();
    c.drawPath(gem, Paint()..color = _sec);
    c.drawPath(gem, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3);
    final facetL = Path()
      ..moveTo(cx, cy - r * 0.8)
      ..lineTo(cx, cy + r * 0.85)
      ..lineTo(cx - r * 0.5, cy - r * 0.25);
    c.drawPath(facetL, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final facetR = Path()
      ..moveTo(cx, cy - r * 0.8)
      ..lineTo(cx, cy + r * 0.85)
      ..lineTo(cx + r * 0.5, cy - r * 0.25);
    c.drawPath(facetR, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final facetB = Path()
      ..moveTo(cx, cy + r * 0.85)
      ..lineTo(cx + r * 0.6, cy + r * 0.3)
      ..lineTo(cx - r * 0.6, cy + r * 0.3);
    c.drawPath(facetB, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final shine = Path()
      ..moveTo(cx - r * 0.15, cy - r * 0.45)
      ..lineTo(cx - r * 0.05, cy - r * 0.2)
      ..lineTo(cx - r * 0.2, cy - r * 0.35)
      ..close();
    c.drawPath(shine, Paint()..color = _wht..style = PaintingStyle.fill);
    _drawN(c, cx, cy, r * 0.3);
  }

  void _drawEpaulettes(Canvas c, double cx, double cy, double r) {
    for (int row = 0; row < 3; row++) {
      final y = cy - r * 0.4 + row * r * 0.3;
      final bar = Rect.fromCenter(center: Offset(cx, y), width: r * 1.2, height: r * 0.15);
      c.drawRRect(RRect.fromRectAndRadius(bar, Radius.circular(r * 0.06)), Paint()..color = _pri);
      c.drawRRect(RRect.fromRectAndRadius(bar, Radius.circular(r * 0.06)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
      final fill = Rect.fromCenter(center: Offset(cx, y), width: r * 1.0, height: r * 0.08);
      c.drawRRect(RRect.fromRectAndRadius(fill, Radius.circular(3)), Paint()..color = row == 0 ? _acc : _sec);
    }
    final eagle = Path()
      ..moveTo(cx, cy + r * 0.55)
      ..lineTo(cx - r * 0.2, cy + r * 0.7)
      ..lineTo(cx - r * 0.1, cy + r * 0.75)
      ..lineTo(cx, cy + r * 0.6)
      ..lineTo(cx + r * 0.1, cy + r * 0.75)
      ..lineTo(cx + r * 0.2, cy + r * 0.7)
      ..close();
    c.drawPath(eagle, Paint()..color = _gld..style = PaintingStyle.fill);
    c.drawPath(eagle, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawN(c, cx, cy + r * 0.65, r * 0.3);
  }

  void _drawRain(Canvas c, double cx, double cy, double r) {
    final cloudL = Rect.fromCenter(center: Offset(cx - r * 0.3, cy - r * 0.2), width: r * 0.7, height: r * 0.45);
    c.drawOval(cloudL, Paint()..color = _sec);
    c.drawOval(cloudL, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final cloudR = Rect.fromCenter(center: Offset(cx + r * 0.3, cy - r * 0.2), width: r * 0.7, height: r * 0.45);
    c.drawOval(cloudR, Paint()..color = _sec);
    c.drawOval(cloudR, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final cloudM = Rect.fromCenter(center: Offset(cx, cy - r * 0.35), width: r * 0.6, height: r * 0.45);
    c.drawOval(cloudM, Paint()..color = _sec);
    c.drawOval(cloudM, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final drops = [Offset(-0.3, 0.3), Offset(-0.1, 0.45), Offset(0.1, 0.35), Offset(0.35, 0.5), Offset(-0.2, 0.55)];
    for (final d in drops) {
      final dx = cx + d.dx * r;
      final dy = cy + d.dy * r;
      final drop = Path()
        ..moveTo(dx, dy)
        ..lineTo(dx - r * 0.03, dy + r * 0.12)
        ..lineTo(dx + r * 0.03, dy + r * 0.12)
        ..close();
      c.drawPath(drop, Paint()..color = _sec);
      c.drawPath(drop, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    _drawN(c, cx, cy + r * 0.6, r * 0.35);
  }

  void _drawFlying(Canvas c, double cx, double cy, double r) {
    final wingL = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx - r * 0.3, cy - r * 0.6, cx - r * 0.8, cy - r * 0.4, cx - r * 0.7, cy + r * 0.1)
      ..cubicTo(cx - r * 0.6, cy - r * 0.1, cx - r * 0.3, cy - r * 0.1, cx, cy + r * 0.2)
      ..close();
    c.drawPath(wingL, Paint()..color = _sec);
    c.drawPath(wingL, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final wingR = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx + r * 0.3, cy - r * 0.6, cx + r * 0.8, cy - r * 0.4, cx + r * 0.7, cy + r * 0.1)
      ..cubicTo(cx + r * 0.6, cy - r * 0.1, cx + r * 0.3, cy - r * 0.1, cx, cy + r * 0.2)
      ..close();
    c.drawPath(wingR, Paint()..color = _sec);
    c.drawPath(wingR, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final body = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 0.35, height: r * 0.5));
    c.drawPath(body, Paint()..color = _pri);
    c.drawPath(body, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r * 0.12 : r * 0.05;
      final sx = cx + rad * math.cos(a);
      final sy = cy + rad * math.sin(a);
      if (i == 0) { star.moveTo(sx, sy); } else { star.lineTo(sx, sy); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    _drawN(c, cx, cy + r * 0.55, r * 0.35);
  }

  void _drawSuperhero(Canvas c, double cx, double cy, double r) {
    final shield = Path()
      ..moveTo(cx, cy - r * 0.85)
      ..lineTo(cx + r * 0.7, cy - r * 0.5)
      ..lineTo(cx + r * 0.7, cy + r * 0.25)
      ..cubicTo(cx + r * 0.7, cy + r * 0.6, cx, cy + r * 0.85, cx, cy + r * 0.85)
      ..cubicTo(cx, cy + r * 0.85, cx - r * 0.7, cy + r * 0.6, cx - r * 0.7, cy + r * 0.25)
      ..lineTo(cx - r * 0.7, cy - r * 0.5)
      ..close();
    c.drawPath(shield, Paint()..color = _pri);
    c.drawPath(shield, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3);
    final innerShield = Path()
      ..moveTo(cx, cy - r * 0.6)
      ..lineTo(cx + r * 0.45, cy - r * 0.35)
      ..lineTo(cx + r * 0.45, cy + r * 0.15)
      ..cubicTo(cx + r * 0.45, cy + r * 0.38, cx, cy + r * 0.55, cx, cy + r * 0.55)
      ..cubicTo(cx, cy + r * 0.55, cx - r * 0.45, cy + r * 0.38, cx - r * 0.45, cy + r * 0.15)
      ..lineTo(cx - r * 0.45, cy - r * 0.35)
      ..close();
    c.drawPath(innerShield, Paint()..color = _wht);
    c.drawPath(innerShield, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r * 0.3 : r * 0.12;
      final sx = cx + rad * math.cos(a);
      final sy = cy + rad * math.sin(a);
      if (i == 0) { star.moveTo(sx, sy); } else { star.lineTo(sx, sy); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _drawN(c, cx, cy, r * 0.35);
  }

  void _drawShadow(Canvas c, double cx, double cy, double r) {
    final moon = Path()
      ..addArc(Rect.fromCenter(center: Offset(cx - r * 0.15, cy), width: r * 1.2, height: r * 1.2), -math.pi * 0.6, math.pi * 1.2)
      ..close();
    c.drawPath(moon, Paint()..color = _pri);
    c.drawPath(moon, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3);
    final innerMoon = Path()
      ..addArc(Rect.fromCenter(center: Offset(cx - r * 0.05, cy), width: r * 0.85, height: r * 0.85), -math.pi * 0.6, math.pi * 1.2)
      ..close();
    c.drawPath(innerMoon, Paint()..color = _sec);
    c.drawPath(innerMoon, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final star1 = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 3 + i * math.pi / 5;
      final rad = i.isEven ? r * 0.12 : r * 0.05;
      final sx = cx + r * 0.3 + rad * math.cos(a);
      final sy = cy - r * 0.3 + rad * math.sin(a);
      if (i == 0) { star1.moveTo(sx, sy); } else { star1.lineTo(sx, sy); }
    }
    star1.close();
    c.drawPath(star1, Paint()..color = _acc..style = PaintingStyle.fill);
    c.drawPath(star1, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    _drawN(c, cx - r * 0.1, cy + r * 0.55, r * 0.3);
  }

  void _drawCommand(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.85, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy), r * 0.85, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3);
    c.drawCircle(Offset(cx, cy), r * 0.7, Paint()..color = _sec);
    c.drawCircle(Offset(cx, cy), r * 0.7, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r * 0.42 : r * 0.18;
      final sx = cx + rad * math.cos(a);
      final sy = cy + rad * math.sin(a);
      if (i == 0) { star.moveTo(sx, sy); } else { star.lineTo(sx, sy); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _pri..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final inner = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r * 0.22 : r * 0.09;
      final sx = cx + rad * math.cos(a);
      final sy = cy + rad * math.sin(a);
      if (i == 0) { inner.moveTo(sx, sy); } else { inner.lineTo(sx, sy); }
    }
    inner.close();
    c.drawPath(inner, Paint()..color = _acc..style = PaintingStyle.fill);
    c.drawPath(inner, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int i = 0; i < 24; i++) {
      final a = i * 2 * math.pi / 24;
      final dotR = r * 0.03;
      c.drawCircle(Offset(cx + r * 0.78 * math.cos(a), cy + r * 0.78 * math.sin(a)), dotR, Paint()..color = _gld);
    }
    _drawN(c, cx, cy, r * 0.2);
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
