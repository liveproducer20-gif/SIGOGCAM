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
  Color get _brn => unlocked ? const Color(0xFFCD7F32) : Colors.grey.shade400;
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

  // ── 005: Agente Amateur ── simple star badge ──────────────────────────
  void _drawShield(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy - 5 * s), 65 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 5 * s), 65 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // 10-point star
    final List<double> px = [100, 115, 145, 125, 135, 100, 65, 75, 55, 85];
    final List<double> py = [45, 70, 65, 90, 120, 105, 120, 90, 65, 70, 45];
    final star = Path();
    star.moveTo(cx + (px[0] - 100) * s, cy + (py[0] - 100) * s);
    for (int i = 1; i < 10; i++) {
      star.lineTo(cx + (px[i] - 100) * s, cy + (py[i] - 100) * s);
    }
    star.close();
    c.drawPath(star, Paint()..color = _brn..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy - 12 * s), 18 * s, Paint()..color = _wht..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    _drawN(c, cx, cy - 6 * s, r * 0.6);
  }

  // ── 010: Novato Diligente ── clipboard with chart ────────────────────
  void _drawPen(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final body = Rect.fromCenter(center: Offset(cx, cy + 5 * s), width: 120 * s, height: 140 * s);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(6 * s)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(6 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    for (int i = 0; i < 3; i++) {
      final ly = cy + (-35 + i * 20) * s;
      c.drawLine(Offset(cx - 40 * s, ly), Offset(cx + 40 * s, ly), Paint()..color = _drk..strokeWidth = 1.5 * s);
    }
    final chart = Path()
      ..moveTo(cx - 50 * s, cy + 50 * s)
      ..lineTo(cx - 30 * s, cy + 30 * s)
      ..lineTo(cx, cy + 45 * s)
      ..lineTo(cx + 30 * s, cy + 25 * s)
      ..lineTo(cx + 45 * s, cy + 40 * s);
    c.drawPath(chart, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    c.drawCircle(Offset(cx + 45 * s, cy + 35 * s), 5 * s, Paint()..color = _acc);
    _drawN(c, cx, cy + 65 * s, r * 0.4);
  }

  // ── 020: Aprendiz Constante ── clipboard with header tab ────────────
  void _drawNotepad(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final body = Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 100 * s, height: 150 * s);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(5 * s)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(5 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    final header = Rect.fromCenter(center: Offset(cx + 5 * s, cy - 35 * s), width: 120 * s, height: 15 * s);
    c.drawRRect(RRect.fromRectAndRadius(header, Radius.circular(3 * s)), Paint()..color = _sec);
    final tab = Rect.fromCenter(center: Offset(cx + 5 * s, cy - 58 * s), width: 30 * s, height: 25 * s);
    c.drawRRect(RRect.fromRectAndRadius(tab, Radius.circular(4 * s)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(tab, Radius.circular(4 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    for (int i = 0; i < 3; i++) {
      final ly = cy + (-15 + i * 20) * s;
      c.drawLine(Offset(cx - 30 * s, ly), Offset(cx + 40 * s, ly), Paint()..color = _drk..strokeWidth = 2 * s);
    }
    c.drawCircle(Offset(cx + 45 * s, cy + 35 * s), 5 * s, Paint()..color = _acc);
    _drawN(c, cx, cy + 55 * s, r * 0.4);
  }

  // ── 030: Investigador Tenaz ── shield with magnifying center ──────
  void _drawRadio(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final shield = Path()
      ..moveTo(cx, cy - 85 * s)
      ..lineTo(cx + 75 * s, cy - 35 * s)
      ..lineTo(cx + 75 * s, cy + 25 * s)
      ..cubicTo(cx + 75 * s, cy + 70 * s, cx, cy + 95 * s, cx, cy + 95 * s)
      ..cubicTo(cx, cy + 95 * s, cx - 75 * s, cy + 70 * s, cx - 75 * s, cy + 25 * s)
      ..lineTo(cx - 75 * s, cy - 35 * s)
      ..close();
    c.drawPath(shield, Paint()..color = _wht);
    c.drawPath(shield, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3.5 * s);
    // Inner eye/heart shape
    final inner = Path()
      ..moveTo(cx - 40 * s, cy - 5 * s)
      ..cubicTo(cx - 40 * s, cy - 25 * s, cx - 25 * s, cy - 25 * s, cx, cy - 5 * s)
      ..cubicTo(cx + 25 * s, cy - 25 * s, cx + 40 * s, cy - 25 * s, cx + 40 * s, cy - 5 * s)
      ..cubicTo(cx + 40 * s, cy + 20 * s, cx, cy + 25 * s, cx, cy + 25 * s)
      ..cubicTo(cx, cy + 25 * s, cx - 40 * s, cy + 20 * s, cx - 40 * s, cy - 5 * s)
      ..close();
    c.drawPath(inner, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    final diamond = Path()
      ..moveTo(cx, cy - 15 * s)
      ..lineTo(cx + 15 * s, cy - 5 * s)
      ..lineTo(cx, cy + 5 * s)
      ..lineTo(cx - 15 * s, cy - 5 * s)
      ..close();
    c.drawPath(diamond, Paint()..color = _acc);
    c.drawPath(diamond, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy, r * 0.4);
  }

  // ── 045: Analista Curioso ── camera body with lens ───────────────
  void _drawCamera(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final body = Rect.fromCenter(center: Offset(cx, cy + 5 * s), width: 130 * s, height: 95 * s);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(12 * s)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(12 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Flash
    final flash = Rect.fromCenter(center: Offset(cx + 85 * s, cy - 13 * s), width: 40 * s, height: 30 * s);
    c.drawRRect(RRect.fromRectAndRadius(flash, Radius.circular(6 * s)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(flash, Radius.circular(6 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Lens area
    final lens = Rect.fromCenter(center: Offset(cx - 20 * s, cy + 2 * s), width: 60 * s, height: 55 * s);
    c.drawRRect(RRect.fromRectAndRadius(lens, Radius.circular(8 * s)), Paint()..color = _wht);
    c.drawOval(lens, Paint()..color = _wht);
    c.drawOval(lens, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx - 20 * s, cy + 2 * s), 12 * s, Paint()..color = _drk);
    c.drawCircle(Offset(cx - 20 * s, cy + 2 * s), 5 * s, Paint()..color = _acc);
    // Bottom decoration
    final bottom = Path()
      ..moveTo(cx - 45 * s, cy + 35 * s)
      ..lineTo(cx - 20 * s, cy + 25 * s)
      ..lineTo(cx + 5 * s, cy + 35 * s);
    c.drawPath(bottom, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    _drawN(c, cx + 20 * s, cy + 45 * s, r * 0.35);
  }

  // ── 060: Buzo de Datos ── square frame with target ──────────────
  void _drawWhistle(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final body = Rect.fromCenter(center: Offset(cx, cy), width: 120 * s, height: 120 * s);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(12 * s)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(12 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    c.drawCircle(Offset(cx, cy - 5 * s), 28 * s, Paint()..color = _sec);
    c.drawCircle(Offset(cx, cy - 5 * s), 28 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy - 5 * s), 14 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 5 * s), 14 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawCircle(Offset(cx, cy - 5 * s), 5 * s, Paint()..color = _acc);
    // Bottom waves
    final wave = Path()
      ..moveTo(cx - 40 * s, cy + 20 * s)
      ..lineTo(cx - 20 * s, cy + 10 * s)
      ..lineTo(cx, cy + 25 * s)
      ..lineTo(cx + 20 * s, cy + 10 * s)
      ..lineTo(cx + 40 * s, cy + 20 * s);
    c.drawPath(wave, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    _drawN(c, cx, cy + 45 * s, r * 0.4);
  }

  // ── 075: Detective de Escritorio ── magnifying glass ────────────
  void _drawMagnifier(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy - 20 * s), 55 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 20 * s), 55 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3.5 * s);
    c.drawCircle(Offset(cx, cy - 20 * s), 38 * s, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy - 20 * s), 18 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy - 20 * s), 18 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawCircle(Offset(cx, cy - 20 * s), 7 * s, Paint()..color = _pri);
    // Handle
    final hL = Rect.fromCenter(center: Offset(cx - 35 * s, cy + 30 * s), width: 20 * s, height: 12 * s);
    c.drawRRect(RRect.fromRectAndRadius(hL, Radius.circular(3 * s)), Paint()..color = _pri);
    final hR = Rect.fromCenter(center: Offset(cx + 25 * s, cy + 30 * s), width: 20 * s, height: 12 * s);
    c.drawRRect(RRect.fromRectAndRadius(hR, Radius.circular(3 * s)), Paint()..color = _pri);
    c.drawLine(Offset(cx - 35 * s, cy + 30 * s), Offset(cx - 25 * s, cy), Paint()..color = _drk..strokeWidth = 2.5 * s);
    c.drawLine(Offset(cx + 25 * s, cy + 30 * s), Offset(cx + 25 * s, cy), Paint()..color = _drk..strokeWidth = 2.5 * s);
    _drawN(c, cx, cy + 55 * s, r * 0.35);
  }

  // ── 095: Estratega Metódico ── clipboard with clip ─────────────
  void _drawCompass(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final body = Rect.fromCenter(center: Offset(cx, cy + 5 * s), width: 130 * s, height: 145 * s);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(8 * s)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(8 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    final inner = Rect.fromCenter(center: Offset(cx, cy + 5 * s), width: 110 * s, height: 125 * s);
    c.drawRRect(RRect.fromRectAndRadius(inner, Radius.circular(5 * s)), Paint()..color = _wht);
    // Clip
    final clip = Rect.fromCenter(center: Offset(cx, cy - 48 * s), width: 30 * s, height: 25 * s);
    c.drawRRect(RRect.fromRectAndRadius(clip, Radius.circular(5 * s)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(clip, Radius.circular(5 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    final clInner = Rect.fromCenter(center: Offset(cx, cy - 48 * s), width: 24 * s, height: 10 * s);
    c.drawRRect(RRect.fromRectAndRadius(clInner, Radius.circular(2 * s)), Paint()..color = _wht);
    // Lines
    for (int i = 0; i < 3; i++) {
      final ly = cy + (-35 + i * 15) * s;
      c.drawLine(Offset(cx - 40 * s, ly), Offset(cx + 40 * s, ly), Paint()..color = _drk..strokeWidth = 2 * s);
    }
    // Stamp
    final stamp = Rect.fromCenter(center: Offset(cx + 30 * s, cy + 15 * s), width: 18 * s, height: 18 * s);
    c.drawRRect(RRect.fromRectAndRadius(stamp, Radius.circular(3 * s)), Paint()..color = _acc);
    c.drawRRect(RRect.fromRectAndRadius(stamp, Radius.circular(3 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy + 60 * s, r * 0.4);
  }

  // ── 115: Guardia Constante ── badge/shield with body ──────────
  void _drawStarBadge(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy - 6 * s), width: 80 * s, height: 60 * s), Paint()..color = _sec);
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy - 6 * s), width: 80 * s, height: 60 * s), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    c.drawLine(Offset(cx, cy - 60 * s), Offset(cx, cy), Paint()..color = _drk..strokeWidth = 2 * s);
    c.drawLine(Offset(cx - 40 * s, cy - 30 * s), Offset(cx + 40 * s, cy - 30 * s), Paint()..color = _drk..strokeWidth = 2 * s);
    // Lower body
    final lower = Rect.fromCenter(center: Offset(cx, cy + 25 * s), width: 70 * s, height: 55 * s);
    c.drawRRect(RRect.fromRectAndRadius(lower, Radius.circular(6 * s)), Paint()..color = _pri);
    final lowerIn = Rect.fromCenter(center: Offset(cx, cy + 25 * s), width: 60 * s, height: 40 * s);
    c.drawRRect(RRect.fromRectAndRadius(lowerIn, Radius.circular(3 * s)), Paint()..color = _sec);
    c.drawCircle(Offset(cx, cy + 25 * s), 8 * s, Paint()..color = _acc);
    // Legs
    c.drawLine(Offset(cx - 35 * s, cy + 55 * s), Offset(cx - 45 * s, cy + 75 * s), Paint()..color = _drk..strokeWidth = 2.5 * s);
    c.drawLine(Offset(cx + 35 * s, cy + 55 * s), Offset(cx + 45 * s, cy + 75 * s), Paint()..color = _drk..strokeWidth = 2.5 * s);
    _drawN(c, cx, cy + 25 * s, r * 0.35);
  }

  // ── 135: Sheriff de los Datos ── 5-point sheriff star ──────────
  void _drawSheriffStar(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final star = Path();
    final List<double> px = [100, 112, 150, 120, 132, 100, 68, 80, 50, 88];
    final List<double> py = [20, 55, 55, 80, 118, 95, 118, 80, 55, 55];
    star.moveTo(cx + (px[0] - 100) * s, cy + (py[0] - 100) * s);
    for (int i = 1; i < 10; i++) {
      star.lineTo(cx + (px[i] - 100) * s, cy + (py[i] - 100) * s);
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc..style = PaintingStyle.fill);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    c.drawCircle(Offset(cx, cy - 30 * s), 22 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 30 * s), 22 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy - 30 * s), 10 * s, Paint()..color = _pri);
    // Rays
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final ex = cx + 25 * s * math.cos(a);
      final ey = cy - 30 * s + 25 * s * math.sin(a);
      c.drawLine(Offset(cx, cy - 30 * s), Offset(ex, ey), Paint()..color = _acc..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
    }
    _drawN(c, cx, cy + 35 * s, r * 0.35);
  }

  // ── 155: Oficial de Primera ── badge with shield inset ─────────
  void _drawBriefcase(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final body = Rect.fromCenter(center: Offset(cx, cy + 5 * s), width: 130 * s, height: 140 * s);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(10 * s)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(10 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Header bar
    final hdr = Rect.fromCenter(center: Offset(cx, cy - 55 * s), width: 130 * s, height: 25 * s);
    c.drawRRect(RRect.fromRectAndRadius(hdr, Radius.circular(10 * s)), Paint()..color = _pri);
    // Inner shield area
    final inner = Rect.fromCenter(center: Offset(cx, cy + 5 * s), width: 80 * s, height: 80 * s);
    c.drawRRect(RRect.fromRectAndRadius(inner, Radius.circular(6 * s)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(inner, Radius.circular(6 * s)), Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy + 5 * s), 20 * s, Paint()..color = _sec);
    c.drawCircle(Offset(cx, cy + 5 * s), 8 * s, Paint()..color = _acc);
    // Bottom lines
    c.drawLine(Offset(cx - 40 * s, cy + 45 * s), Offset(cx + 40 * s, cy + 45 * s), Paint()..color = _drk..strokeWidth = 2 * s);
    c.drawLine(Offset(cx - 50 * s, cy + 60 * s), Offset(cx + 50 * s, cy + 60 * s), Paint()..color = _drk..strokeWidth = 2 * s);
    _drawN(c, cx, cy + 75 * s, r * 0.35);
  }

  // ── 175: Veterano en Servicio ── clipboard with star ──────────
  void _drawClipboard(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final body = Rect.fromCenter(center: Offset(cx, cy + 5 * s), width: 100 * s, height: 135 * s);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(6 * s)), Paint()..color = _pri);
    final inner = Rect.fromCenter(center: Offset(cx, cy + 5 * s), width: 90 * s, height: 125 * s);
    c.drawRRect(RRect.fromRectAndRadius(inner, Radius.circular(4 * s)), Paint()..color = _wht);
    // Clip
    final clip = Rect.fromCenter(center: Offset(cx, cy - 42 * s), width: 20 * s, height: 20 * s);
    c.drawRRect(RRect.fromRectAndRadius(clip, Radius.circular(4 * s)), Paint()..color = _acc);
    c.drawRRect(RRect.fromRectAndRadius(clip, Radius.circular(4 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawCircle(Offset(cx, cy - 42 * s), 3 * s, Paint()..color = _pri);
    // Lines
    for (int i = 0; i < 3; i++) {
      final ly = cy + (-30 + i * 15) * s;
      c.drawLine(Offset(cx - 30 * s, ly), Offset(cx + 30 * s, ly), Paint()..color = _drk..strokeWidth = 2 * s);
    }
    // Stamp
    final stamp = Rect.fromCenter(center: Offset(cx + 20 * s, cy + 20 * s), width: 18 * s, height: 18 * s);
    c.drawRRect(RRect.fromRectAndRadius(stamp, Radius.circular(3 * s)), Paint()..color = _sec);
    _drawN(c, cx, cy + 65 * s, r * 0.4);
  }

  // ── 195: Centinela Incansable ── watchtower / beacon ──────────
  void _drawWatchtower(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Pillar
    final pillar = Rect.fromCenter(center: Offset(cx, cy + 15 * s), width: 50 * s, height: 95 * s);
    c.drawRRect(RRect.fromRectAndRadius(pillar, Radius.circular(5 * s)), Paint()..color = _pri);
    final pillarIn = Rect.fromCenter(center: Offset(cx, cy + 15 * s), width: 44 * s, height: 89 * s);
    c.drawRRect(RRect.fromRectAndRadius(pillarIn, Radius.circular(3 * s)), Paint()..color = _wht);
    // Top triangle / roof
    final roof = Path()
      ..moveTo(cx, cy - 80 * s)
      ..lineTo(cx + 35 * s, cy - 35 * s)
      ..lineTo(cx - 35 * s, cy - 35 * s)
      ..close();
    c.drawPath(roof, Paint()..color = _sec);
    c.drawPath(roof, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Beacon light
    final light = Rect.fromCenter(center: Offset(cx, cy - 55 * s), width: 20 * s, height: 15 * s);
    c.drawRRect(RRect.fromRectAndRadius(light, Radius.circular(4 * s)), Paint()..color = _acc);
    // Base steps
    final step1 = Rect.fromCenter(center: Offset(cx, cy + 45 * s), width: 90 * s, height: 8 * s);
    c.drawRRect(RRect.fromRectAndRadius(step1, Radius.circular(3 * s)), Paint()..color = _pri);
    final step2 = Rect.fromCenter(center: Offset(cx, cy + 57 * s), width: 110 * s, height: 10 * s);
    c.drawRRect(RRect.fromRectAndRadius(step2, Radius.circular(4 * s)), Paint()..color = _sec);
    _drawN(c, cx, cy + 70 * s, r * 0.35);
  }

  // ── 215: Portador de la Verdad ── scroll / certificate ────────
  void _drawScroll(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final scroll = Path()
      ..moveTo(cx - 40 * s, cy + 70 * s)
      ..lineTo(cx - 40 * s, cy + 40 * s)
      ..lineTo(cx - 50 * s, cy + 30 * s)
      ..lineTo(cx - 50 * s, cy - 40 * s)
      ..cubicTo(cx - 50 * s, cy - 65 * s, cx, cy - 70 * s, cx, cy - 70 * s)
      ..cubicTo(cx, cy - 70 * s, cx + 50 * s, cy - 65 * s, cx + 50 * s, cy - 40 * s)
      ..lineTo(cx + 50 * s, cy + 30 * s)
      ..lineTo(cx + 40 * s, cy + 40 * s)
      ..lineTo(cx + 40 * s, cy + 70 * s)
      ..close();
    c.drawPath(scroll, Paint()..color = _wht);
    c.drawPath(scroll, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Inner paper
    final paper = Rect.fromCenter(center: Offset(cx, cy - 5 * s), width: 90 * s, height: 70 * s);
    c.drawRRect(RRect.fromRectAndRadius(paper, Radius.circular(4 * s)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(paper, Radius.circular(4 * s)), Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Lines
    for (int i = 0; i < 3; i++) {
      final ly = cy + (-25 + i * 15) * s;
      c.drawLine(Offset(cx - 30 * s, ly), Offset(cx + 30 * s, ly), Paint()..color = _drk..strokeWidth = 1.5 * s);
    }
    // Seal circle
    c.drawCircle(Offset(cx, cy - 59 * s), 8 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy - 59 * s), 8 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy + 50 * s, r * 0.4);
  }

  // ── 235: Guardian del Honor ── laurel / circle ─────────────────
  void _drawLaurel(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy - 10 * s), 65 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy - 10 * s), 65 * s, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    c.drawCircle(Offset(cx, cy - 10 * s), 50 * s, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy - 10 * s), 35 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 10 * s), 35 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Inner star
    final star = Path();
    final List<double> px = [100, 108, 128, 114, 117, 100, 83, 86, 72, 92];
    final List<double> py = [65, 80, 83, 95, 113, 103, 113, 95, 83, 80];
    star.moveTo(cx + (px[0] - 100) * s, cy - 10 * s + (py[0] - 90) * s);
    for (int i = 1; i < 10; i++) {
      star.lineTo(cx + (px[i] - 100) * s, cy - 10 * s + (py[i] - 90) * s);
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Laurel branches
    final branchL = Path()
      ..moveTo(cx - 65 * s, cy - 40 * s)
      ..cubicTo(cx - 50 * s, cy - 55 * s, cx - 30 * s, cy - 45 * s, cx - 30 * s, cy - 45 * s);
    c.drawPath(branchL, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    final branchR = Path()
      ..moveTo(cx + 65 * s, cy - 40 * s)
      ..cubicTo(cx + 50 * s, cy - 55 * s, cx + 30 * s, cy - 45 * s, cx + 30 * s, cy - 45 * s);
    c.drawPath(branchR, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    // Bottom ribbon
    final ribbon = Path()
      ..moveTo(cx - 50 * s, cy + 35 * s)
      ..cubicTo(cx - 25 * s, cy + 50 * s, cx, cy + 35 * s, cx, cy + 35 * s)
      ..cubicTo(cx, cy + 35 * s, cx + 25 * s, cy + 50 * s, cx + 50 * s, cy + 35 * s);
    c.drawPath(ribbon, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    _drawN(c, cx, cy - 10 * s, r * 0.3);
  }

  // ── 255: Agente Especial ── shield with S ──────────────────────
  void _drawAgent(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final shield = Path()
      ..moveTo(cx, cy - 85 * s)
      ..lineTo(cx + 70 * s, cy - 40 * s)
      ..lineTo(cx + 70 * s, cy + 20 * s)
      ..cubicTo(cx + 70 * s, cy + 60 * s, cx, cy + 90 * s, cx, cy + 90 * s)
      ..cubicTo(cx, cy + 90 * s, cx - 70 * s, cy + 60 * s, cx - 70 * s, cy + 20 * s)
      ..lineTo(cx - 70 * s, cy - 40 * s)
      ..close();
    c.drawPath(shield, Paint()..color = _pri);
    c.drawPath(shield, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Inner shield outline
    final inner = Path()
      ..moveTo(cx, cy - 60 * s)
      ..lineTo(cx + 50 * s, cy - 28 * s)
      ..lineTo(cx + 50 * s, cy + 15 * s)
      ..cubicTo(cx + 50 * s, cy + 45 * s, cx, cy + 68 * s, cx, cy + 68 * s)
      ..cubicTo(cx, cy + 68 * s, cx - 50 * s, cy + 45 * s, cx - 50 * s, cy + 15 * s)
      ..lineTo(cx - 50 * s, cy - 28 * s)
      ..close();
    c.drawPath(inner, Paint()..color = _wht..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // S-letter star
    final star = Path();
    final List<double> px = [100, 110, 128, 115, 118, 100, 82, 85, 72, 90];
    final List<double> py = [60, 75, 78, 90, 108, 98, 108, 90, 78, 75];
    star.moveTo(cx + (px[0] - 100) * s, cy + (py[0] - 100) * s);
    for (int i = 1; i < 10; i++) {
      star.lineTo(cx + (px[i] - 100) * s, cy + (py[i] - 100) * s);
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    _drawN(c, cx, cy + 55 * s, r * 0.35);
  }

  // ── 275: Papa Mike ── circular badge with wings ─────────────────
  void _drawPapamike(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Gold circle
    c.drawCircle(Offset(cx, cy - 20 * s), 60 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy - 20 * s), 60 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    c.drawCircle(Offset(cx, cy - 20 * s), 45 * s, Paint()..color = _wht..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy - 20 * s), 30 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 20 * s), 30 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Inner star
    final star = Path();
    final List<double> px = [100, 106, 120, 109, 112, 100, 88, 91, 80, 94];
    final List<double> py = [60, 72, 75, 85, 100, 92, 100, 85, 75, 72];
    star.moveTo(cx + (px[0] - 100) * s, cy - 20 * s + (py[0] - 80) * s);
    for (int i = 1; i < 10; i++) {
      star.lineTo(cx + (px[i] - 100) * s, cy - 20 * s + (py[i] - 80) * s);
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    // Wing blocks
    final wL = Rect.fromCenter(center: Offset(cx - 55 * s, cy + 30 * s), width: 30 * s, height: 25 * s);
    c.drawRRect(RRect.fromRectAndRadius(wL, Radius.circular(5 * s)), Paint()..color = _pri);
    final wR = Rect.fromCenter(center: Offset(cx + 25 * s, cy + 30 * s), width: 30 * s, height: 25 * s);
    c.drawRRect(RRect.fromRectAndRadius(wR, Radius.circular(5 * s)), Paint()..color = _pri);
    c.drawLine(Offset(cx - 40 * s, cy + 30 * s), Offset(cx - 20 * s, cy + 5 * s), Paint()..color = _drk..strokeWidth = 2.5 * s);
    c.drawLine(Offset(cx + 40 * s, cy + 30 * s), Offset(cx + 20 * s, cy + 5 * s), Paint()..color = _drk..strokeWidth = 2.5 * s);
    _drawN(c, cx, cy - 20 * s, r * 0.3);
  }

  // ── 295: Agente Loco ── crazy face with text ──────────────────
  void _drawCrazy(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Head
    c.drawCircle(Offset(cx, cy - 5 * s), 30 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 5 * s), 30 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Eyes
    c.drawCircle(Offset(cx - 10 * s, cy - 10 * s), 5 * s, Paint()..color = _drk);
    c.drawCircle(Offset(cx + 10 * s, cy - 10 * s), 5 * s, Paint()..color = _drk);
    // Smile
    final smile = Path()
      ..moveTo(cx - 15 * s, cy + 10 * s)
      ..cubicTo(cx, cy + 20 * s, cx + 15 * s, cy + 10 * s, cx + 15 * s, cy + 10 * s);
    c.drawPath(smile, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    // Body/note area
    final body = Rect.fromCenter(center: Offset(cx, cy + 20 * s), width: 90 * s, height: 55 * s);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(6 * s)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(6 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawLine(Offset(cx - 30 * s, cy + 15 * s), Offset(cx + 30 * s, cy + 15 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    c.drawLine(Offset(cx - 30 * s, cy + 30 * s), Offset(cx + 15 * s, cy + 30 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    // Crazy lines radiating from head
    c.drawLine(Offset(cx - 70 * s, cy - 45 * s), Offset(cx - 50 * s, cy - 50 * s), Paint()..color = _sec..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    c.drawLine(Offset(cx + 70 * s, cy - 45 * s), Offset(cx + 50 * s, cy - 50 * s), Paint()..color = _sec..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    c.drawLine(Offset(cx - 65 * s, cy - 20 * s), Offset(cx - 45 * s, cy - 20 * s), Paint()..color = _sec..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    c.drawLine(Offset(cx + 65 * s, cy - 20 * s), Offset(cx + 45 * s, cy - 20 * s), Paint()..color = _sec..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    _drawN(c, cx, cy + 55 * s, r * 0.35);
  }

  // ── 315: Tiburón de los Reportes ── shark + pencil ⚡ ─────────
  void _drawShark(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Shark fin body
    final body = Path()
      ..moveTo(cx - 55 * s, cy + 10 * s)
      ..cubicTo(cx - 55 * s, cy - 45 * s, cx, cy - 50 * s, cx, cy - 50 * s)
      ..cubicTo(cx, cy - 50 * s, cx + 55 * s, cy - 45 * s, cx + 55 * s, cy + 10 * s)
      ..cubicTo(cx + 55 * s, cy + 40 * s, cx + 30 * s, cy + 55 * s, cx, cy + 55 * s)
      ..cubicTo(cx, cy + 55 * s, cx + 55 * s, cy + 80 * s, cx + 55 * s, cy + 85 * s)
      ..lineTo(cx + 15 * s, cy + 68 * s)
      ..cubicTo(cx, cy + 78 * s, cx - 15 * s, cy + 68 * s, cx - 15 * s, cy + 68 * s)
      ..lineTo(cx - 55 * s, cy + 85 * s)
      ..lineTo(cx - 30 * s, cy + 55 * s)
      ..cubicTo(cx - 55 * s, cy + 40 * s, cx - 55 * s, cy + 10 * s, cx - 55 * s, cy + 10 * s)
      ..close();
    c.drawPath(body, Paint()..color = _sec);
    c.drawPath(body, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Inner curve
    final inner = Path()
      ..moveTo(cx - 35 * s, cy + 10 * s)
      ..cubicTo(cx - 35 * s, cy - 25 * s, cx, cy - 28 * s, cx, cy - 28 * s)
      ..cubicTo(cx, cy - 28 * s, cx + 35 * s, cy - 25 * s, cx + 35 * s, cy + 10 * s);
    c.drawPath(inner, Paint()..color = _wht..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Eye
    c.drawCircle(Offset(cx, cy + 12 * s), 14 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy + 12 * s), 7 * s, Paint()..color = _pri);
    // Pencil lines (fins)
    c.drawLine(Offset(cx - 15 * s, cy - 5 * s), Offset(cx - 35 * s, cy - 35 * s), Paint()..color = _acc..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    c.drawLine(Offset(cx + 15 * s, cy - 5 * s), Offset(cx + 35 * s, cy - 35 * s), Paint()..color = _acc..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    _drawN(c, cx, cy + 55 * s, r * 0.35);
  }

  // ── 335: Francotirador Analítico ── crosshairs ─────────────────
  void _drawSniper(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy - 10 * s), 70 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 10 * s), 70 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3.5 * s);
    c.drawCircle(Offset(cx, cy - 10 * s), 52 * s, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    c.drawCircle(Offset(cx, cy - 10 * s), 34 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy - 10 * s), 16 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy - 10 * s), 16 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawCircle(Offset(cx, cy - 10 * s), 6 * s, Paint()..color = _pri);
    // Crosshairs
    c.drawLine(Offset(cx - 75 * s, cy - 10 * s), Offset(cx + 75 * s, cy - 10 * s), Paint()..color = _drk..strokeWidth = 2.5 * s);
    c.drawLine(Offset(cx, cy - 85 * s), Offset(cx, cy + 65 * s), Paint()..color = _drk..strokeWidth = 2.5 * s);
    _drawN(c, cx, cy + 55 * s, r * 0.3);
  }

  // ── 355: El Blanco Perfecto ── target / bullseye ───────────────
  void _drawTarget(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Target circles
    c.drawCircle(Offset(cx, cy - 20 * s), 55 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 20 * s), 55 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    c.drawCircle(Offset(cx, cy - 20 * s), 40 * s, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy - 20 * s), 25 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy - 20 * s), 10 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy - 20 * s), 4 * s, Paint()..color = _pri);
    // Stand
    final stand = Path()
      ..moveTo(cx - 30 * s, cy + 30 * s)
      ..lineTo(cx, cy + 55 * s)
      ..lineTo(cx + 30 * s, cy + 30 * s);
    c.drawPath(stand, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    c.drawLine(Offset(cx, cy + 30 * s), Offset(cx, cy + 60 * s), Paint()..color = _drk..strokeWidth = 2.5 * s);
    _drawN(c, cx, cy + 60 * s, r * 0.35);
  }

  // ── 375: Forense de la Información ── forensic / science ──────
  void _drawForensic(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy - 15 * s), 65 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 15 * s), 65 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Face area
    final face = Rect.fromCenter(center: Offset(cx, cy), width: 56 * s, height: 70 * s);
    c.drawOval(face, Paint()..color = _sec);
    c.drawOval(face, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Hair
    final hair = Path()
      ..moveTo(cx - 15 * s, cy - 35 * s)
      ..cubicTo(cx - 5 * s, cy - 45 * s, cx, cy - 45 * s, cx, cy - 45 * s)
      ..cubicTo(cx, cy - 45 * s, cx + 5 * s, cy - 45 * s, cx + 15 * s, cy - 35 * s);
    c.drawPath(hair, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s..strokeCap = StrokeCap.round);
    // Mouth
    final mouth = Path()
      ..moveTo(cx - 30 * s, cy)
      ..cubicTo(cx - 20 * s, cy - 5 * s, cx - 10 * s, cy + 5 * s, cx, cy)
      ..cubicTo(cx + 10 * s, cy + 5 * s, cx + 20 * s, cy - 5 * s, cx + 30 * s, cy);
    c.drawPath(mouth, Paint()..color = _wht..style = PaintingStyle.stroke..strokeWidth = 2 * s..strokeCap = StrokeCap.round);
    // Eyes
    c.drawCircle(Offset(cx - 20 * s, cy - 15 * s), 3 * s, Paint()..color = _drk);
    c.drawCircle(Offset(cx + 20 * s, cy - 15 * s), 3 * s, Paint()..color = _drk);
    _drawN(c, cx, cy + 55 * s, r * 0.35);
  }

  // ── 395: Élite de los Reportes ── epaulettes / bars ──────────
  void _drawEpaulettes(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final body = Rect.fromCenter(center: Offset(cx, cy + 5 * s), width: 120 * s, height: 140 * s);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(8 * s)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(8 * s)), Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Three horizontal bars
    final colors = [_sec, _acc, _sec];
    for (int i = 0; i < 3; i++) {
      final bar = Rect.fromCenter(center: Offset(cx, cy + (-20 + i * 35) * s), width: 100 * s, height: 25 * s);
      c.drawRRect(RRect.fromRectAndRadius(bar, Radius.circular(5 * s)), Paint()..color = colors[i]);
    }
    // Bottom star
    c.drawCircle(Offset(cx, cy + 65 * s), 10 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy + 65 * s), 10 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    _drawN(c, cx, cy + 75 * s, r * 0.3);
  }

  // ── 415: Cazador de Tormentas ── clouds with lightning ────────
  void _drawRain(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Three clouds
    c.drawOval(Rect.fromCenter(center: Offset(cx - 45 * s, cy - 10 * s), width: 76 * s, height: 50 * s), Paint()..color = _sec);
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy - 20 * s), width: 84 * s, height: 56 * s), Paint()..color = _pri);
    c.drawOval(Rect.fromCenter(center: Offset(cx + 45 * s, cy - 10 * s), width: 76 * s, height: 48 * s), Paint()..color = _sec);
    // Center cloud top
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy - 28 * s), width: 60 * s, height: 40 * s), Paint()..color = _wht);
    // Rain drops
    final drops = [
      Offset(cx - 35 * s, cy + 25 * s), Offset(cx - 5 * s, cy + 30 * s),
      Offset(cx + 25 * s, cy + 25 * s), Offset(cx + 45 * s, cy + 22 * s),
      Offset(cx - 20 * s, cy + 55 * s), Offset(cx + 10 * s, cy + 57 * s),
      Offset(cx + 35 * s, cy + 40 * s),
    ];
    for (final d in drops) {
      final drop = Path()
        ..moveTo(d.dx, d.dy)
        ..lineTo(d.dx - 2 * s, d.dy + 12 * s)
        ..lineTo(d.dx + 2 * s, d.dy + 12 * s)
        ..close();
      c.drawPath(drop, Paint()..color = _wht..style = PaintingStyle.fill);
    }
    _drawN(c, cx, cy + 65 * s, r * 0.35);
  }

  // ── 435: Águila en Picada ── flying / diving ─────────────────
  void _drawFlying(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Rotated document cards
    final cards = <void Function()>[
      () {
        c.save();
        c.translate(cx - 40 * s, cy - 10 * s);
        c.rotate(-20 * math.pi / 180);
        final card = Rect.fromCenter(center: Offset.zero, width: 60 * s, height: 80 * s);
        c.drawRRect(RRect.fromRectAndRadius(card, Radius.circular(4 * s)), Paint()..color = _wht);
        c.drawRRect(RRect.fromRectAndRadius(card, Radius.circular(4 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
        c.drawLine(Offset(-20 * s, -10 * s), Offset(20 * s, -10 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
        c.restore();
      },
      () {
        c.save();
        c.translate(cx, cy - 25 * s);
        c.rotate(15 * math.pi / 180);
        final card = Rect.fromCenter(center: Offset.zero, width: 60 * s, height: 80 * s);
        c.drawRRect(RRect.fromRectAndRadius(card, Radius.circular(4 * s)), Paint()..color = _wht);
        c.drawRRect(RRect.fromRectAndRadius(card, Radius.circular(4 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
        c.drawLine(Offset(-20 * s, -10 * s), Offset(20 * s, -10 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
        c.restore();
      },
      () {
        c.save();
        c.translate(cx + 40 * s, cy - 10 * s);
        c.rotate(-10 * math.pi / 180);
        final card = Rect.fromCenter(center: Offset.zero, width: 60 * s, height: 80 * s);
        c.drawRRect(RRect.fromRectAndRadius(card, Radius.circular(4 * s)), Paint()..color = _wht);
        c.drawRRect(RRect.fromRectAndRadius(card, Radius.circular(4 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
        c.drawLine(Offset(-20 * s, -10 * s), Offset(20 * s, -10 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
        c.restore();
      },
      () {
        c.save();
        c.translate(cx - 20 * s, cy + 5 * s);
        c.rotate(25 * math.pi / 180);
        final card = Rect.fromCenter(center: Offset.zero, width: 60 * s, height: 80 * s);
        c.drawRRect(RRect.fromRectAndRadius(card, Radius.circular(4 * s)), Paint()..color = _sec);
        c.drawRRect(RRect.fromRectAndRadius(card, Radius.circular(4 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
        c.restore();
      },
    ];
    for (final card in cards) {
      card();
    }
    _drawN(c, cx, cy + 60 * s, r * 0.35);
  }

  // ── 455: Superhéroe Operativo ── superhero ────────────────────
  void _drawSuperhero(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Head
    c.drawCircle(Offset(cx, cy - 35 * s), 25 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 35 * s), 25 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Eyes
    c.drawCircle(Offset(cx - 8 * s, cy - 38 * s), 4 * s, Paint()..color = _drk);
    c.drawCircle(Offset(cx + 8 * s, cy - 38 * s), 4 * s, Paint()..color = _drk);
    // Smile
    final smile = Path()
      ..moveTo(cx - 12 * s, cy - 28 * s)
      ..cubicTo(cx, cy - 20 * s, cx + 12 * s, cy - 28 * s, cx + 12 * s, cy - 28 * s);
    c.drawPath(smile, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s..strokeCap = StrokeCap.round);
    // Cape/body
    final cape = Path()
      ..moveTo(cx - 25 * s, cy - 12 * s)
      ..lineTo(cx - 40 * s, cy + 75 * s)
      ..lineTo(cx, cy + 30 * s)
      ..lineTo(cx + 40 * s, cy + 75 * s)
      ..lineTo(cx + 25 * s, cy - 12 * s);
    c.drawPath(cape, Paint()..color = _pri);
    c.drawPath(cape, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Chest star
    final star = Path();
    final List<double> px = [100, 108, 125, 113, 115, 100, 85, 87, 75, 92];
    final List<double> py = [95, 110, 113, 125, 142, 133, 142, 125, 113, 110];
    star.moveTo(cx + (px[0] - 100) * s, cy + (py[0] - 100) * s);
    for (int i = 1; i < 10; i++) {
      star.lineTo(cx + (px[i] - 100) * s, cy + (py[i] - 100) * s);
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    _drawN(c, cx, cy + 60 * s, r * 0.35);
  }

  // ── 475: Sombra del Deber ── shadow / stealth ─────────────────
  void _drawShadow(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Head (dark)
    c.drawCircle(Offset(cx, cy - 35 * s), 22 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy - 35 * s), 14 * s, Paint()..color = _sec);
    // Eyes (glowing)
    c.drawCircle(Offset(cx - 6 * s, cy - 38 * s), 3 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx + 6 * s, cy - 38 * s), 3 * s, Paint()..color = _acc);
    // Body
    final body = Rect.fromCenter(center: Offset(cx, cy + 5 * s), width: 70 * s, height: 65 * s);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(8 * s)), Paint()..color = _pri);
    // Chest plate
    final plate = Rect.fromCenter(center: Offset(cx, cy + 5 * s), width: 60 * s, height: 35 * s);
    c.drawRRect(RRect.fromRectAndRadius(plate, Radius.circular(4 * s)), Paint()..color = _wht);
    // Lines on chest
    c.drawLine(Offset(cx - 20 * s, cy + 5 * s), Offset(cx + 20 * s, cy + 5 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    c.drawLine(Offset(cx - 20 * s, cy + 17 * s), Offset(cx + 10 * s, cy + 17 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    // Bottom ribbon
    final rib = Path()
      ..moveTo(cx - 35 * s, cy + 50 * s)
      ..lineTo(cx - 50 * s, cy + 68 * s)
      ..lineTo(cx - 25 * s, cy + 60 * s)
      ..lineTo(cx - 15 * s, cy + 75 * s)
      ..lineTo(cx - 5 * s, cy + 58 * s)
      ..lineTo(cx, cy + 80 * s)
      ..lineTo(cx + 5 * s, cy + 58 * s)
      ..lineTo(cx + 15 * s, cy + 75 * s)
      ..lineTo(cx + 25 * s, cy + 60 * s)
      ..lineTo(cx + 50 * s, cy + 68 * s)
      ..lineTo(cx + 35 * s, cy + 50 * s);
    c.drawPath(rib, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 2 * s..strokeCap = StrokeCap.round);
    _drawN(c, cx, cy + 65 * s, r * 0.35);
  }

  // ── 500: Comando de Elite ── command elite ────────────────────
  void _drawCommand(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Outer circles
    c.drawCircle(Offset(cx, cy - 10 * s), 78 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy - 10 * s), 78 * s, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 3.5 * s);
    c.drawCircle(Offset(cx, cy - 10 * s), 62 * s, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    c.drawCircle(Offset(cx, cy - 10 * s), 48 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 10 * s), 48 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Outer 10-point star
    final starO = Path();
    final List<double> pxO = [100, 108, 125, 113, 116, 100, 84, 87, 75, 92];
    final List<double> pyO = [60, 73, 76, 88, 105, 95, 105, 88, 76, 73];
    starO.moveTo(cx + (pxO[0] - 100) * s, cy - 10 * s + (pyO[0] - 90) * s);
    for (int i = 1; i < 10; i++) {
      starO.lineTo(cx + (pxO[i] - 100) * s, cy - 10 * s + (pyO[i] - 90) * s);
    }
    starO.close();
    c.drawPath(starO, Paint()..color = _pri);
    c.drawPath(starO, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Inner 10-point star
    final starI = Path();
    final List<double> pxI = [100, 105, 115, 108, 110, 100, 90, 92, 85, 95];
    final List<double> pyI = [67, 76, 78, 86, 98, 91, 98, 86, 78, 76];
    starI.moveTo(cx + (pxI[0] - 100) * s, cy - 10 * s + (pyI[0] - 90) * s);
    for (int i = 1; i < 10; i++) {
      starI.lineTo(cx + (pxI[i] - 100) * s, cy - 10 * s + (pyI[i] - 90) * s);
    }
    starI.close();
    c.drawPath(starI, Paint()..color = _acc);
    c.drawPath(starI, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Laurel branches
    final branchL = Path()
      ..moveTo(cx - 65 * s, cy - 50 * s)
      ..cubicTo(cx - 45 * s, cy - 70 * s, cx - 25 * s, cy - 55 * s, cx - 25 * s, cy - 55 * s);
    c.drawPath(branchL, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
    final branchR = Path()
      ..moveTo(cx + 65 * s, cy - 50 * s)
      ..cubicTo(cx + 45 * s, cy - 70 * s, cx + 25 * s, cy - 55 * s, cx + 25 * s, cy - 55 * s);
    c.drawPath(branchR, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
    // Bottom ribbon
    final ribbon = Path()
      ..moveTo(cx - 58 * s, cy + 45 * s)
      ..cubicTo(cx - 35 * s, cy + 60 * s, cx, cy + 45 * s, cx, cy + 45 * s)
      ..cubicTo(cx, cy + 45 * s, cx + 35 * s, cy + 60 * s, cx + 58 * s, cy + 45 * s);
    c.drawPath(ribbon, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
    _drawN(c, cx, cy - 10 * s, r * 0.25);
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
