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
  Color get _wht => unlocked ? Colors.white : Colors.grey.shade100;
  Color get _slv => unlocked ? const Color(0xFFB0B0B0) : Colors.grey.shade400;
  Color get _brn => unlocked ? const Color(0xFFCD7F32) : Colors.grey.shade500;
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
      case 530: _drawDiamond(canvas, cx, cy, r);
      case 565: _drawCrown(canvas, cx, cy, r);
      case 605: _drawGem(canvas, cx, cy, r);
      case 650: _drawSunburst(canvas, cx, cy, r);
      case 700: _drawWings(canvas, cx, cy, r);
      case 755: _drawPedestal(canvas, cx, cy, r);
      case 800: _drawGrandStar(canvas, cx, cy, r);
      default: _drawShield(canvas, cx, cy, r);
    }
  }

  // ── 005: Agente Amateur ── policía novato ────────────────────────────
  void _drawShield(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Circle background
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Police cap body (dome)
    final cap = Path()
      ..moveTo(cx - 45 * s, cy + 5 * s)
      ..cubicTo(cx - 45 * s, cy - 40 * s, cx + 45 * s, cy - 40 * s, cx + 45 * s, cy + 5 * s)
      ..lineTo(cx - 45 * s, cy + 5 * s)
      ..close();
    c.drawPath(cap, Paint()..color = _pri);
    c.drawPath(cap, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Visor/brim
    final brim = Path()
      ..moveTo(cx - 55 * s, cy + 5 * s)
      ..cubicTo(cx - 30 * s, cy + 18 * s, cx + 30 * s, cy + 18 * s, cx + 55 * s, cy + 5 * s);
    c.drawPath(brim, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3.5 * s..strokeCap = StrokeCap.round);
    // Cap badge (small gold circle)
    c.drawCircle(Offset(cx, cy - 10 * s), 10 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy - 10 * s), 10 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    // Star inside badge
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? 6 * s : 2.5 * s;
      if (i == 0) { star.moveTo(cx + rad * math.cos(a), cy - 10 * s + rad * math.sin(a)); }
      else { star.lineTo(cx + rad * math.cos(a), cy - 10 * s + rad * math.sin(a)); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _pri);
    // Cap band
    c.drawLine(Offset(cx - 45 * s, cy + 5 * s), Offset(cx + 45 * s, cy + 5 * s), Paint()..color = _drk..strokeWidth = 2 * s);
    _drawN(c, cx, cy + 40 * s, r * 0.5);
  }

  // ── 010: Redactor Novato ── lápiz escribiendo ────────────────────
  void _drawPen(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Paper
    final paper = Rect.fromCenter(center: Offset(cx, cy + 5 * s), width: 70 * s, height: 60 * s);
    c.drawRRect(RRect.fromRectAndRadius(paper, Radius.circular(4 * s)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(paper, Radius.circular(4 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Lines on paper
    c.drawLine(Offset(cx - 25 * s, cy - 5 * s), Offset(cx + 20 * s, cy - 5 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    c.drawLine(Offset(cx - 25 * s, cy + 5 * s), Offset(cx + 25 * s, cy + 5 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    c.drawLine(Offset(cx - 25 * s, cy + 15 * s), Offset(cx + 15 * s, cy + 15 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    // Pencil
    final pencil = Path()
      ..moveTo(cx - 40 * s, cy + 45 * s)
      ..lineTo(cx + 10 * s, cy - 50 * s)
      ..lineTo(cx + 25 * s, cy - 45 * s)
      ..lineTo(cx - 20 * s, cy + 40 * s)
      ..close();
    c.drawPath(pencil, Paint()..color = _acc);
    c.drawPath(pencil, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Pencil tip
    final tip = Path()
      ..moveTo(cx + 10 * s, cy - 50 * s)
      ..lineTo(cx + 18 * s, cy - 58 * s)
      ..lineTo(cx + 25 * s, cy - 45 * s)
      ..close();
    c.drawPath(tip, Paint()..color = _drk);
    c.drawPath(tip, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy + 42 * s, r * 0.45);
  }

  // ── 020: Cronista Operativo ── libro con pluma de ave ────────────
  void _drawNotepad(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Circle bg
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Open book
    final book = Path()
      ..moveTo(cx - 45 * s, cy + 30 * s)
      ..lineTo(cx - 45 * s, cy - 15 * s)
      ..cubicTo(cx - 45 * s, cy - 30 * s, cx, cy - 40 * s, cx, cy - 40 * s)
      ..cubicTo(cx, cy - 40 * s, cx + 45 * s, cy - 30 * s, cx + 45 * s, cy - 15 * s)
      ..lineTo(cx + 45 * s, cy + 30 * s)
      ..cubicTo(cx + 45 * s, cy + 20 * s, cx, cy + 10 * s, cx, cy + 10 * s)
      ..cubicTo(cx, cy + 10 * s, cx - 45 * s, cy + 20 * s, cx - 45 * s, cy + 30 * s)
      ..close();
    c.drawPath(book, Paint()..color = _wht);
    c.drawPath(book, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Spine line
    c.drawLine(Offset(cx, cy - 40 * s), Offset(cx, cy + 10 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    // Feather quill
    final quill = Path()
      ..moveTo(cx + 15 * s, cy - 25 * s)
      ..cubicTo(cx + 40 * s, cy - 55 * s, cx + 50 * s, cy - 65 * s, cx + 35 * s, cy - 60 * s)
      ..cubicTo(cx + 20 * s, cy - 55 * s, cx + 10 * s, cy - 30 * s, cx + 5 * s, cy - 15 * s)
      ..lineTo(cx + 15 * s, cy - 25 * s)
      ..close();
    c.drawPath(quill, Paint()..color = _pri);
    c.drawPath(quill, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    // Quill tip
    c.drawLine(Offset(cx + 5 * s, cy - 15 * s), Offset(cx - 5 * s, cy + 5 * s), Paint()..color = _acc..strokeWidth = 2 * s..strokeCap = StrokeCap.round);
    _drawN(c, cx, cy + 50 * s, r * 0.45);
  }

  // ── 030: Agente Comprometido ── reloj ──────────────────────────
  void _drawRadio(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Clock rim
    c.drawCircle(Offset(cx, cy - 5 * s), 42 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy - 5 * s), 42 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Clock face
    c.drawCircle(Offset(cx, cy - 5 * s), 35 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 5 * s), 35 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Hour markers (12 dots)
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6 - math.pi / 2;
      final mx = cx + 30 * s * math.cos(a);
      final my = cy - 5 * s + 30 * s * math.sin(a);
      if (i % 3 == 0) {
        c.drawCircle(Offset(mx, my), 3 * s, Paint()..color = _drk);
      } else {
        c.drawCircle(Offset(mx, my), 1.5 * s, Paint()..color = _drk);
      }
    }
    // Hour hand (pointing ~10:10)
    c.drawLine(Offset(cx, cy - 5 * s), Offset(cx - 12 * s, cy - 22 * s), Paint()..color = _drk..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
    // Minute hand
    c.drawLine(Offset(cx, cy - 5 * s), Offset(cx + 20 * s, cy - 18 * s), Paint()..color = _drk..strokeWidth = 2 * s..strokeCap = StrokeCap.round);
    // Center dot
    c.drawCircle(Offset(cx, cy - 5 * s), 3 * s, Paint()..color = _acc);
    _drawN(c, cx, cy + 42 * s, r * 0.45);
  }

  // ── 045: Reportero Activo ── cámara de televisión ──────────────
  void _drawCamera(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Camera body
    final body = Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 85 * s, height: 60 * s);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(8 * s)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(8 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Lens
    c.drawCircle(Offset(cx - 10 * s, cy + 2 * s), 18 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx - 10 * s, cy + 2 * s), 18 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawCircle(Offset(cx - 10 * s, cy + 2 * s), 10 * s, Paint()..color = _sec);
    c.drawCircle(Offset(cx - 10 * s, cy + 2 * s), 5 * s, Paint()..color = _acc);
    // Viewfinder / flash on top
    final vf = Rect.fromCenter(center: Offset(cx + 25 * s, cy - 25 * s), width: 18 * s, height: 12 * s);
    c.drawRRect(RRect.fromRectAndRadius(vf, Radius.circular(3 * s)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(vf, Radius.circular(3 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    // Antenna
    c.drawLine(Offset(cx + 15 * s, cy - 28 * s), Offset(cx + 20 * s, cy - 50 * s), Paint()..color = _drk..strokeWidth = 2 * s);
    c.drawCircle(Offset(cx + 20 * s, cy - 50 * s), 3 * s, Paint()..color = _acc);
    _drawN(c, cx, cy + 42 * s, r * 0.45);
  }

  // ── 060: Guardia de Novedades ── escudo ─────────────────────────
  void _drawWhistle(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Shield shape
    final shield = Path()
      ..moveTo(cx, cy - 50 * s)
      ..lineTo(cx + 45 * s, cy - 20 * s)
      ..lineTo(cx + 45 * s, cy + 20 * s)
      ..cubicTo(cx + 45 * s, cy + 40 * s, cx, cy + 55 * s, cx, cy + 55 * s)
      ..cubicTo(cx, cy + 55 * s, cx - 45 * s, cy + 40 * s, cx - 45 * s, cy + 20 * s)
      ..lineTo(cx - 45 * s, cy - 20 * s)
      ..close();
    c.drawPath(shield, Paint()..color = _pri);
    c.drawPath(shield, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Inner shield
    final inner = Path()
      ..moveTo(cx, cy - 35 * s)
      ..lineTo(cx + 30 * s, cy - 12 * s)
      ..lineTo(cx + 30 * s, cy + 15 * s)
      ..cubicTo(cx + 30 * s, cy + 30 * s, cx, cy + 40 * s, cx, cy + 40 * s)
      ..cubicTo(cx, cy + 40 * s, cx - 30 * s, cy + 30 * s, cx - 30 * s, cy + 15 * s)
      ..lineTo(cx - 30 * s, cy - 12 * s)
      ..close();
    c.drawPath(inner, Paint()..color = _sec);
    c.drawPath(inner, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Star on shield
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? 10 * s : 4 * s;
      if (i == 0) { star.moveTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
      else { star.lineTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy + 45 * s, r * 0.4);
  }

  // ── 075: Operador Estratégico ── joystick ─────────────────────
  void _drawMagnifier(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Controller base
    final base = Rect.fromCenter(center: Offset(cx, cy + 10 * s), width: 80 * s, height: 40 * s);
    c.drawRRect(RRect.fromRectAndRadius(base, Radius.circular(12 * s)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(base, Radius.circular(12 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // D-pad (left)
    final dpad = Rect.fromCenter(center: Offset(cx - 20 * s, cy + 10 * s), width: 10 * s, height: 18 * s);
    c.drawRRect(RRect.fromRectAndRadius(dpad, Radius.circular(2 * s)), Paint()..color = _drk);
    // Buttons (right)
    c.drawCircle(Offset(cx + 18 * s, cy + 5 * s), 5 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx + 18 * s, cy + 15 * s), 5 * s, Paint()..color = _sec);
    // Joystick top
    final stick = Rect.fromCenter(center: Offset(cx, cy - 15 * s), width: 14 * s, height: 14 * s);
    c.drawCircle(stick.center, 7 * s, Paint()..color = _sec);
    c.drawCircle(stick.center, 7 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy + 45 * s, r * 0.45);
  }

  // ── 095: Coordinador de Cartillas ── engranaje ────────────────
  void _drawCompass(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Gear teeth (12 triangles)
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final inner = 38 * s;
      final outer = 48 * s;
      final tooth = Path()
        ..moveTo(cx + inner * math.cos(a - 0.12), cy + inner * math.sin(a - 0.12))
        ..lineTo(cx + outer * math.cos(a), cy + outer * math.sin(a))
        ..lineTo(cx + inner * math.cos(a + 0.12), cy + inner * math.sin(a + 0.12))
        ..close();
      c.drawPath(tooth, Paint()..color = _pri);
      c.drawPath(tooth, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1 * s);
    }
    // Gear inner circle
    c.drawCircle(Offset(cx, cy), 34 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy), 34 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Center hole
    c.drawCircle(Offset(cx, cy), 12 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 12 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Inner cross
    c.drawLine(Offset(cx - 8 * s, cy), Offset(cx + 8 * s, cy), Paint()..color = _drk..strokeWidth = 2 * s);
    c.drawLine(Offset(cx, cy - 8 * s), Offset(cx, cy + 8 * s), Paint()..color = _drk..strokeWidth = 2 * s);
    _drawN(c, cx, cy + 48 * s, r * 0.4);
  }

  // ── 115: Supervisor de Incidencias ── lupa ─────────────────────
  void _drawStarBadge(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Lens
    c.drawCircle(Offset(cx - 5 * s, cy - 8 * s), 34 * s, Paint()..color = _sec);
    c.drawCircle(Offset(cx - 5 * s, cy - 8 * s), 34 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    c.drawCircle(Offset(cx - 5 * s, cy - 8 * s), 26 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx - 5 * s, cy - 8 * s), 26 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Glass reflection
    final refl = Path()
      ..moveTo(cx - 18 * s, cy - 22 * s)
      ..cubicTo(cx - 10 * s, cy - 30 * s, cx + 5 * s, cy - 22 * s, cx + 5 * s, cy - 22 * s);
    c.drawPath(refl, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 2 * s..strokeCap = StrokeCap.round);
    // Handle
    c.save();
    c.translate(cx + 28 * s, cy + 30 * s);
    c.rotate(45 * math.pi / 180);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 42 * s, height: 10 * s), Radius.circular(4 * s)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 42 * s, height: 10 * s), Radius.circular(4 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.restore();
    _drawN(c, cx, cy + 48 * s, r * 0.4);
  }

  // ── 135: Agente Destacado ── medalla con cóndor ─────────────
  void _drawSheriffStar(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Medal outer ring
    c.drawCircle(Offset(cx, cy - 5 * s), 42 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy - 5 * s), 42 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Medal inner
    c.drawCircle(Offset(cx, cy - 5 * s), 32 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 5 * s), 32 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Condor silhouette (simplified)
    final condor = Path()
      ..moveTo(cx, cy - 30 * s)
      ..lineTo(cx - 5 * s, cy - 18 * s)
      ..lineTo(cx - 22 * s, cy - 22 * s)
      ..lineTo(cx - 15 * s, cy - 12 * s)
      ..lineTo(cx - 28 * s, cy - 10 * s)
      ..lineTo(cx - 15 * s, cy - 5 * s)
      ..lineTo(cx - 12 * s, cy + 2 * s)
      ..lineTo(cx - 5 * s, cy - 5 * s)
      ..lineTo(cx, cy + 5 * s)
      ..lineTo(cx + 5 * s, cy - 5 * s)
      ..lineTo(cx + 12 * s, cy + 2 * s)
      ..lineTo(cx + 15 * s, cy - 5 * s)
      ..lineTo(cx + 28 * s, cy - 10 * s)
      ..lineTo(cx + 15 * s, cy - 12 * s)
      ..lineTo(cx + 22 * s, cy - 22 * s)
      ..lineTo(cx + 5 * s, cy - 18 * s)
      ..close();
    c.drawPath(condor, Paint()..color = _pri);
    c.drawPath(condor, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    // Ribbon top
    final ribbon = Rect.fromCenter(center: Offset(cx, cy - 40 * s), width: 30 * s, height: 10 * s);
    c.drawRRect(RRect.fromRectAndRadius(ribbon, Radius.circular(3 * s)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(ribbon, Radius.circular(3 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    c.drawLine(Offset(cx - 10 * s, cy - 40 * s), Offset(cx - 10 * s, cy - 48 * s), Paint()..color = _sec..strokeWidth = 3 * s);
    c.drawLine(Offset(cx + 10 * s, cy - 40 * s), Offset(cx + 10 * s, cy - 48 * s), Paint()..color = _sec..strokeWidth = 3 * s);
    _drawN(c, cx, cy + 42 * s, r * 0.4);
  }

  // ── 155: Especialista Operativo ── llave inglesa ──────────────
  void _drawBriefcase(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Wrench handle
    final handle = Path()
      ..moveTo(cx - 8 * s, cy + 40 * s)
      ..lineTo(cx - 8 * s, cy - 15 * s)
      ..lineTo(cx + 8 * s, cy - 15 * s)
      ..lineTo(cx + 8 * s, cy + 40 * s)
      ..close();
    c.drawPath(handle, Paint()..color = _slv);
    c.drawPath(handle, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Wrench head (C-shape)
    final head = Path()
      ..moveTo(cx - 18 * s, cy - 15 * s)
      ..lineTo(cx - 18 * s, cy - 45 * s)
      ..lineTo(cx + 18 * s, cy - 45 * s)
      ..lineTo(cx + 18 * s, cy - 15 * s)
      ..lineTo(cx + 8 * s, cy - 15 * s)
      ..lineTo(cx + 8 * s, cy - 35 * s)
      ..lineTo(cx - 8 * s, cy - 35 * s)
      ..lineTo(cx - 8 * s, cy - 15 * s)
      ..close();
    c.drawPath(head, Paint()..color = _slv);
    c.drawPath(head, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Jaw details
    c.drawLine(Offset(cx - 15 * s, cy - 40 * s), Offset(cx + 15 * s, cy - 40 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy + 48 * s, r * 0.4);
  }

  // ── 175: Experto en Reportes ── agente con lentes ───────────
  void _drawClipboard(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Head
    c.drawCircle(Offset(cx, cy - 5 * s), 28 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 5 * s), 28 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Hair
    final hair = Path()
      ..moveTo(cx - 25 * s, cy - 20 * s)
      ..cubicTo(cx - 25 * s, cy - 38 * s, cx + 25 * s, cy - 38 * s, cx + 25 * s, cy - 20 * s);
    c.drawPath(hair, Paint()..color = _pri);
    c.drawPath(hair, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    // Glasses (two circles + bridge)
    c.drawCircle(Offset(cx - 10 * s, cy - 5 * s), 10 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawCircle(Offset(cx + 10 * s, cy - 5 * s), 10 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawLine(Offset(cx, cy - 5 * s), Offset(cx, cy - 5 * s), Paint()..color = _drk..strokeWidth = 2 * s);
    // Eyes behind glasses
    c.drawCircle(Offset(cx - 10 * s, cy - 5 * s), 3 * s, Paint()..color = _drk);
    c.drawCircle(Offset(cx + 10 * s, cy - 5 * s), 3 * s, Paint()..color = _drk);
    // Smile
    final smile = Path()
      ..moveTo(cx - 8 * s, cy + 10 * s)
      ..cubicTo(cx, cy + 16 * s, cx + 8 * s, cy + 10 * s, cx + 8 * s, cy + 10 * s);
    c.drawPath(smile, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s..strokeCap = StrokeCap.round);
    _drawN(c, cx, cy + 42 * s, r * 0.45);
  }

  // ── 195: Centinela Institucional ── caballero medieval ───────
  void _drawWatchtower(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Knight helmet
    final helm = Path()
      ..moveTo(cx - 30 * s, cy - 20 * s)
      ..cubicTo(cx - 30 * s, cy - 50 * s, cx + 30 * s, cy - 50 * s, cx + 30 * s, cy - 20 * s)
      ..lineTo(cx + 30 * s, cy + 5 * s)
      ..cubicTo(cx + 30 * s, cy + 15 * s, cx - 30 * s, cy + 15 * s, cx - 30 * s, cy + 5 * s)
      ..close();
    c.drawPath(helm, Paint()..color = _slv);
    c.drawPath(helm, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Visor slit
    final visor = Path()
      ..moveTo(cx - 20 * s, cy - 10 * s)
      ..lineTo(cx + 20 * s, cy - 10 * s)
      ..lineTo(cx + 12 * s, cy + 2 * s)
      ..lineTo(cx - 12 * s, cy + 2 * s)
      ..close();
    c.drawPath(visor, Paint()..color = _drk);
    // Cross on helmet
    final cross = Path()
      ..moveTo(cx, cy - 45 * s)
      ..lineTo(cx, cy - 25 * s)
      ..moveTo(cx - 8 * s, cy - 35 * s)
      ..lineTo(cx + 8 * s, cy - 35 * s);
    c.drawPath(cross, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    _drawN(c, cx, cy + 42 * s, r * 0.45);
  }

  // ── 215: Maestro de las Cartillas ── pizarra con libros ──────
  void _drawScroll(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy + 2 * s), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy + 2 * s), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Chalkboard
    final board = Rect.fromCenter(center: Offset(cx, cy - 10 * s), width: 75 * s, height: 55 * s);
    c.drawRRect(RRect.fromRectAndRadius(board, Radius.circular(4 * s)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(board, Radius.circular(4 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Chalk writing (simple lines)
    c.drawLine(Offset(cx - 20 * s, cy - 22 * s), Offset(cx + 10 * s, cy - 22 * s), Paint()..color = _wht..strokeWidth = 1.5 * s);
    c.drawLine(Offset(cx - 20 * s, cy - 14 * s), Offset(cx + 18 * s, cy - 14 * s), Paint()..color = _wht..strokeWidth = 1.5 * s);
    c.drawLine(Offset(cx - 20 * s, cy - 6 * s), Offset(cx + 5 * s, cy - 6 * s), Paint()..color = _wht..strokeWidth = 1.5 * s);
    // Books below
    final book1 = Rect.fromCenter(center: Offset(cx - 18 * s, cy + 30 * s), width: 30 * s, height: 12 * s);
    c.drawRRect(RRect.fromRectAndRadius(book1, Radius.circular(2 * s)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(book1, Radius.circular(2 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    final book2 = Rect.fromCenter(center: Offset(cx + 8 * s, cy + 33 * s), width: 32 * s, height: 14 * s);
    c.drawRRect(RRect.fromRectAndRadius(book2, Radius.circular(2 * s)), Paint()..color = _acc);
    c.drawRRect(RRect.fromRectAndRadius(book2, Radius.circular(2 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    final book3 = Rect.fromCenter(center: Offset(cx + 25 * s, cy + 28 * s), width: 20 * s, height: 10 * s);
    c.drawRRect(RRect.fromRectAndRadius(book3, Radius.circular(2 * s)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(book3, Radius.circular(2 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy + 50 * s, r * 0.4);
  }

  // ── 235: Leyenda Operativa ── bruja ──────────────────────────
  void _drawLaurel(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Witch hat
    final hat = Path()
      ..moveTo(cx - 5 * s, cy - 15 * s)
      ..lineTo(cx - 40 * s, cy + 30 * s)
      ..lineTo(cx + 40 * s, cy + 30 * s)
      ..lineTo(cx + 5 * s, cy - 15 * s)
      ..lineTo(cx + 25 * s, cy - 35 * s)
      ..lineTo(cx, cy - 55 * s)
      ..lineTo(cx - 25 * s, cy - 35 * s)
      ..close();
    c.drawPath(hat, Paint()..color = _pri);
    c.drawPath(hat, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Hat band
    c.drawLine(Offset(cx - 38 * s, cy + 22 * s), Offset(cx + 38 * s, cy + 22 * s), Paint()..color = _acc..strokeWidth = 3 * s);
    // Hat buckle
    final buckle = Rect.fromCenter(center: Offset(cx, cy + 22 * s), width: 8 * s, height: 8 * s);
    c.drawRect(buckle, Paint()..color = _drk);
    c.drawRect(buckle, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    // Stars around hat
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      final sx = cx + 38 * s * math.cos(a);
      final sy = cy - 30 * s + 25 * s * math.sin(a);
      c.drawCircle(Offset(sx, sy), 3 * s, Paint()..color = _acc);
    }
    _drawN(c, cx, cy + 48 * s, r * 0.4);
  }

  // ── 255: Super Agente ── agente con muchas medallas ─────────
  void _drawAgent(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Chest/shoulders
    final chest = Path()
      ..moveTo(cx - 35 * s, cy + 35 * s)
      ..lineTo(cx - 35 * s, cy - 5 * s)
      ..cubicTo(cx - 35 * s, cy - 25 * s, cx + 35 * s, cy - 25 * s, cx + 35 * s, cy - 5 * s)
      ..lineTo(cx + 35 * s, cy + 35 * s)
      ..close();
    c.drawPath(chest, Paint()..color = _pri);
    c.drawPath(chest, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Collar/lapel
    final lapel = Path()
      ..moveTo(cx - 5 * s, cy - 5 * s)
      ..lineTo(cx, cy + 10 * s)
      ..lineTo(cx + 5 * s, cy - 5 * s);
    c.drawPath(lapel, Paint()..color = _wht);
    // Medals (row of circles)
    final medalColors = [_acc, _sec, _acc, _slv, _acc];
    for (int i = 0; i < 5; i++) {
      final mx = cx - 20 * s + i * 10 * s;
      c.drawCircle(Offset(mx, cy + 15 * s), 4 * s, Paint()..color = medalColors[i]);
      c.drawCircle(Offset(mx, cy + 15 * s), 4 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1 * s);
      c.drawLine(Offset(mx, cy + 11 * s), Offset(mx, cy + 3 * s), Paint()..color = _acc..strokeWidth = 1.5 * s);
    }
    // Star on chest
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? 6 * s : 2.5 * s;
      if (i == 0) { star.moveTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
      else { star.lineTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1 * s);
    _drawN(c, cx, cy + 48 * s, r * 0.4);
  }

  // ── 275: El mejor de los Papamike ── tres medallas ──────────
  void _drawPapamike(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // 3 medals in a row: Gold, Silver, Bronze
    // Gold (center, highest)
    c.drawCircle(Offset(cx, cy - 10 * s), 18 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy - 10 * s), 18 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    final starG = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? 10 * s : 4 * s;
      if (i == 0) { starG.moveTo(cx + rad * math.cos(a), cy - 10 * s + rad * math.sin(a)); }
      else { starG.lineTo(cx + rad * math.cos(a), cy - 10 * s + rad * math.sin(a)); }
    }
    starG.close();
    c.drawPath(starG, Paint()..color = _pri);
    c.drawPath(starG, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1 * s);
    // Ribbon gold
    c.drawLine(Offset(cx, cy - 28 * s), Offset(cx, cy - 38 * s), Paint()..color = _sec..strokeWidth = 2 * s);
    // Silver (left)
    c.drawCircle(Offset(cx - 28 * s, cy + 10 * s), 14 * s, Paint()..color = _slv);
    c.drawCircle(Offset(cx - 28 * s, cy + 10 * s), 14 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawLine(Offset(cx - 28 * s, cy - 4 * s), Offset(cx - 28 * s, cy - 14 * s), Paint()..color = _slv..strokeWidth = 2 * s);
    final starS = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? 7 * s : 3 * s;
      if (i == 0) { starS.moveTo(cx - 28 * s + rad * math.cos(a), cy + 10 * s + rad * math.sin(a)); }
      else { starS.lineTo(cx - 28 * s + rad * math.cos(a), cy + 10 * s + rad * math.sin(a)); }
    }
    starS.close();
    c.drawPath(starS, Paint()..color = _pri);
    // Bronze (right)
    c.drawCircle(Offset(cx + 28 * s, cy + 10 * s), 14 * s, Paint()..color = _brn);
    c.drawCircle(Offset(cx + 28 * s, cy + 10 * s), 14 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawLine(Offset(cx + 28 * s, cy - 4 * s), Offset(cx + 28 * s, cy - 14 * s), Paint()..color = _brn..strokeWidth = 2 * s);
    _drawN(c, cx, cy + 42 * s, r * 0.35);
  }

  // ── 295: El loco de las Cartillas ── persona loca ────────────
  void _drawCrazy(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Wild hair
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4 - math.pi / 2;
      final start = 24 * s;
      final end = 36 * s;
      c.drawLine(
        Offset(cx + start * math.cos(a), cy - 8 * s + start * math.sin(a) * 0.6),
        Offset(cx + end * math.cos(a), cy - 8 * s + end * math.sin(a) * 0.6),
        Paint()..color = _drk..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round,
      );
    }
    // Face
    c.drawCircle(Offset(cx, cy - 2 * s), 24 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 2 * s), 24 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Crazy eyes (different sizes)
    c.drawCircle(Offset(cx - 10 * s, cy - 5 * s), 6 * s, Paint()..color = _drk);
    c.drawCircle(Offset(cx + 10 * s, cy - 5 * s), 4 * s, Paint()..color = _drk);
    // Big grin
    final mouth = Path()
      ..moveTo(cx - 14 * s, cy + 6 * s)
      ..cubicTo(cx - 8 * s, cy + 16 * s, cx + 8 * s, cy + 16 * s, cx + 14 * s, cy + 6 * s);
    c.drawPath(mouth, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    // Tongue
    final tongue = Path()
      ..moveTo(cx - 4 * s, cy + 10 * s)
      ..cubicTo(cx, cy + 18 * s, cx + 4 * s, cy + 10 * s, cx + 4 * s, cy + 10 * s);
    c.drawPath(tongue, Paint()..color = _sec..style = PaintingStyle.fill);
    _drawN(c, cx, cy + 42 * s, r * 0.45);
  }

  // ── 315: Tiburón de los reportes ── tiburón ──────────────────
  void _drawShark(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Shark body
    final body = Path()
      ..moveTo(cx - 10 * s, cy + 30 * s)
      ..cubicTo(cx - 30 * s, cy + 10 * s, cx - 35 * s, cy - 10 * s, cx - 25 * s, cy - 25 * s)
      ..cubicTo(cx - 15 * s, cy - 40 * s, cx + 15 * s, cy - 40 * s, cx + 25 * s, cy - 25 * s)
      ..cubicTo(cx + 35 * s, cy - 10 * s, cx + 30 * s, cy + 10 * s, cx + 10 * s, cy + 30 * s)
      ..close();
    c.drawPath(body, Paint()..color = _sec);
    c.drawPath(body, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Dorsal fin
    final fin = Path()
      ..moveTo(cx - 6 * s, cy - 20 * s)
      ..lineTo(cx, cy - 48 * s)
      ..lineTo(cx + 6 * s, cy - 20 * s)
      ..close();
    c.drawPath(fin, Paint()..color = _pri);
    c.drawPath(fin, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Tail
    final tail = Path()
      ..moveTo(cx, cy + 15 * s)
      ..lineTo(cx - 25 * s, cy + 42 * s)
      ..lineTo(cx, cy + 32 * s)
      ..lineTo(cx + 25 * s, cy + 42 * s)
      ..close();
    c.drawPath(tail, Paint()..color = _pri);
    c.drawPath(tail, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Eyes
    c.drawCircle(Offset(cx - 8 * s, cy - 5 * s), 3 * s, Paint()..color = _drk);
    c.drawCircle(Offset(cx + 8 * s, cy - 5 * s), 3 * s, Paint()..color = _drk);
    // Gills
    c.drawLine(Offset(cx - 4 * s, cy + 2 * s), Offset(cx - 12 * s, cy + 8 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    c.drawLine(Offset(cx + 4 * s, cy + 2 * s), Offset(cx + 12 * s, cy + 8 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy + 45 * s, r * 0.4);
  }

  // ── 335: Sniper de novedades ── mira de francotirador ──────────
  void _drawSniper(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Scope body
    c.drawCircle(Offset(cx, cy), 45 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy), 45 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Lens
    c.drawCircle(Offset(cx, cy), 32 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 32 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Crosshairs
    c.drawLine(Offset(cx - 45 * s, cy), Offset(cx + 45 * s, cy), Paint()..color = _drk..strokeWidth = 2 * s);
    c.drawLine(Offset(cx, cy - 45 * s), Offset(cx, cy + 45 * s), Paint()..color = _drk..strokeWidth = 2 * s);
    // Center dot
    c.drawCircle(Offset(cx, cy), 5 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy), 5 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1 * s);
    // Windage/elevation marks
    for (int i = -2; i <= 2; i++) {
      if (i == 0) continue;
      // Top marks
      c.drawLine(Offset(cx - 2 * s, cy + i * 12 * s - 35 * s), Offset(cx + 2 * s, cy + i * 12 * s - 35 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
      // Side marks
      c.drawLine(Offset(cx + i * 12 * s - 35 * s, cy - 2 * s), Offset(cx + i * 12 * s - 35 * s, cy + 2 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    }
    // Scope mounts
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy + 46 * s), width: 30 * s, height: 8 * s), Paint()..color = _slv);
    c.drawRect(Rect.fromCenter(center: Offset(cx, cy + 46 * s), width: 30 * s, height: 8 * s), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy + 50 * s, r * 0.35);
  }

  // ── 355: Tirador de incidencias ── diana con dardos ───────────
  void _drawTarget(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Dartboard concentric rings
    c.drawCircle(Offset(cx, cy - 5 * s), 38 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 5 * s), 38 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy - 5 * s), 28 * s, Paint()..color = _sec);
    c.drawCircle(Offset(cx, cy - 5 * s), 28 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawCircle(Offset(cx, cy - 5 * s), 18 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy - 5 * s), 18 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawCircle(Offset(cx, cy - 5 * s), 8 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy - 5 * s), 8 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    // Division lines (4 quadrants)
    c.drawLine(Offset(cx, cy - 43 * s), Offset(cx, cy + 33 * s), Paint()..color = _drk..strokeWidth = 1 * s);
    c.drawLine(Offset(cx - 38 * s, cy - 5 * s), Offset(cx + 38 * s, cy - 5 * s), Paint()..color = _drk..strokeWidth = 1 * s);
    // Dart 1 (top-left, stuck in board)
    c.drawLine(Offset(cx - 20 * s, cy - 35 * s), Offset(cx - 12 * s, cy - 15 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    c.drawCircle(Offset(cx - 20 * s, cy - 35 * s), 3 * s, Paint()..color = _acc);
    // Dart 2 (top-right)
    c.drawLine(Offset(cx + 22 * s, cy - 30 * s), Offset(cx + 12 * s, cy - 12 * s), Paint()..color = _drk..strokeWidth = 1.5 * s);
    c.drawCircle(Offset(cx + 22 * s, cy - 30 * s), 3 * s, Paint()..color = _sec);
    _drawN(c, cx, cy + 48 * s, r * 0.4);
  }

  // ── 375: Perito de cartillas ── clipboard con checklist ───────
  void _drawForensic(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Clipboard
    final board = Rect.fromCenter(center: Offset(cx, cy + 2 * s), width: 60 * s, height: 72 * s);
    c.drawRRect(RRect.fromRectAndRadius(board, Radius.circular(5 * s)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(board, Radius.circular(5 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Clip at top
    final clip = Rect.fromCenter(center: Offset(cx, cy - 35 * s), width: 20 * s, height: 10 * s);
    c.drawRRect(RRect.fromRectAndRadius(clip, Radius.circular(3 * s)), Paint()..color = _slv);
    c.drawRRect(RRect.fromRectAndRadius(clip, Radius.circular(3 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    // Lines of text
    c.drawLine(Offset(cx - 18 * s, cy - 15 * s), Offset(cx + 18 * s, cy - 15 * s), Paint()..color = _wht..strokeWidth = 1.5 * s);
    c.drawLine(Offset(cx - 18 * s, cy - 5 * s), Offset(cx + 18 * s, cy - 5 * s), Paint()..color = _wht..strokeWidth = 1.5 * s);
    c.drawLine(Offset(cx - 18 * s, cy + 5 * s), Offset(cx + 18 * s, cy + 5 * s), Paint()..color = _wht..strokeWidth = 1.5 * s);
    // Check marks on last two lines
    final check1 = Path()
      ..moveTo(cx + 10 * s, cy + 5 * s)
      ..lineTo(cx + 14 * s, cy + 12 * s)
      ..lineTo(cx + 22 * s, cy + 2 * s);
    c.drawPath(check1, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 2 * s..strokeCap = StrokeCap.round);
    final check2 = Path()
      ..moveTo(cx - 10 * s, cy + 12 * s)
      ..lineTo(cx - 6 * s, cy + 19 * s)
      ..lineTo(cx + 2 * s, cy + 9 * s);
    c.drawPath(check2, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 2 * s..strokeCap = StrokeCap.round);
    _drawN(c, cx, cy + 48 * s, r * 0.4);
  }

  // ── 395: Jefe de Patrulla ── placa de sheriff ─────────────────
  void _drawEpaulettes(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Sheriff star (6-pointed)
    final star = Path();
    for (int i = 0; i < 12; i++) {
      final a = -math.pi / 2 + i * math.pi / 6;
      final rad = i.isEven ? 38 * s : 18 * s;
      if (i == 0) { star.moveTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
      else { star.lineTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Inner circle
    c.drawCircle(Offset(cx, cy), 22 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy), 22 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Text ring dots
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final dx = cx + 30 * s * math.cos(a);
      final dy = cy + 30 * s * math.sin(a);
      c.drawCircle(Offset(dx, dy), 2 * s, Paint()..color = _wht);
    }
    // Center badge
    c.drawCircle(Offset(cx, cy), 8 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy), 8 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy + 48 * s, r * 0.4);
  }

  // ── 415: Lluvia de novedades ── nube con lluvia ───────────────
  void _drawRain(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Cloud (3 merged circles + flat bottom)
    c.drawCircle(Offset(cx - 20 * s, cy - 5 * s), 22 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy - 15 * s), 26 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx + 20 * s, cy - 5 * s), 22 * s, Paint()..color = _pri);
    // Cloud flat bottom
    final bottom = Rect.fromCenter(center: Offset(cx, cy), width: 84 * s, height: 18 * s);
    c.drawRect(bottom, Paint()..color = _pri);
    // Cloud outline
    final outline = Path()
      ..moveTo(cx + 42 * s, cy - 5 * s)
      ..lineTo(cx + 42 * s, cy + 3 * s)
      ..lineTo(cx - 42 * s, cy + 3 * s)
      ..lineTo(cx - 42 * s, cy - 5 * s);
    c.drawPath(outline, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawCircle(Offset(cx - 20 * s, cy - 5 * s), 22 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawCircle(Offset(cx, cy - 15 * s), 26 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    c.drawCircle(Offset(cx + 20 * s, cy - 5 * s), 22 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Rain drops
    for (int i = 0; i < 4; i++) {
      final dx = cx - 20 * s + i * 13 * s;
      final drop = Path()
        ..moveTo(dx, cy + 18 * s)
        ..lineTo(dx - 2 * s, cy + 32 * s)
        ..lineTo(dx + 2 * s, cy + 32 * s)
        ..close();
      c.drawPath(drop, Paint()..color = _sec);
    }
    _drawN(c, cx, cy + 45 * s, r * 0.4);
  }

  // ── 435: Cartillas por doquier ── destellos / chispas ─────────
  void _drawFlying(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Sparkles / stars in different positions
    void drawSparkle(double x, double y, double sz) {
      final lines = [
        Offset(x - sz, y), Offset(x + sz, y),
        Offset(x, y - sz), Offset(x, y + sz),
      ];
      for (int i = 0; i < 2; i++) {
        c.drawLine(lines[i * 2], lines[i * 2 + 1], Paint()..color = _acc..strokeWidth = 2 * s..strokeCap = StrokeCap.round);
      }
    }
    drawSparkle(cx - 30 * s, cy - 25 * s, 8 * s);
    drawSparkle(cx + 30 * s, cy - 20 * s, 10 * s);
    drawSparkle(cx - 20 * s, cy + 15 * s, 12 * s);
    drawSparkle(cx + 25 * s, cy + 20 * s, 7 * s);
    drawSparkle(cx, cy - 5 * s, 15 * s);
    // Small dots between sparkles
    c.drawCircle(Offset(cx - 10 * s, cy - 30 * s), 2 * s, Paint()..color = _sec);
    c.drawCircle(Offset(cx + 15 * s, cy - 35 * s), 2 * s, Paint()..color = _sec);
    c.drawCircle(Offset(cx - 35 * s, cy + 5 * s), 2 * s, Paint()..color = _sec);
    c.drawCircle(Offset(cx + 40 * s, cy + 5 * s), 2 * s, Paint()..color = _sec);
    c.drawCircle(Offset(cx + 5 * s, cy + 30 * s), 2 * s, Paint()..color = _sec);
    _drawN(c, cx, cy + 48 * s, r * 0.4);
  }

  // ── 455: Superhéroe Operativo ── emblema de héroe ─────────────
  void _drawSuperhero(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Shield-like emblem
    final emblem = Path()
      ..moveTo(cx, cy - 45 * s)
      ..lineTo(cx + 35 * s, cy - 15 * s)
      ..lineTo(cx + 35 * s, cy + 15 * s)
      ..cubicTo(cx + 35 * s, cy + 40 * s, cx, cy + 55 * s, cx, cy + 55 * s)
      ..cubicTo(cx, cy + 55 * s, cx - 35 * s, cy + 40 * s, cx - 35 * s, cy + 15 * s)
      ..lineTo(cx - 35 * s, cy - 15 * s)
      ..close();
    c.drawPath(emblem, Paint()..color = _pri);
    c.drawPath(emblem, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Cape flowing behind (drawn inside emblem area)
    final cape = Path()
      ..moveTo(cx - 25 * s, cy - 10 * s)
      ..cubicTo(cx - 30 * s, cy + 15 * s, cx - 15 * s, cy + 30 * s, cx, cy + 35 * s)
      ..cubicTo(cx + 15 * s, cy + 30 * s, cx + 30 * s, cy + 15 * s, cx + 25 * s, cy - 10 * s)
      ..close();
    c.drawPath(cape, Paint()..color = _sec);
    c.drawPath(cape, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Star on chest
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? 12 * s : 5 * s;
      if (i == 0) { star.moveTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
      else { star.lineTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy + 48 * s, r * 0.4);
  }

  // ── 475: Merodeador de incidencias ── huellas ─────────────────
  void _drawShadow(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Footprints
    void drawFootprint(double fx, double fy, int dir) {
      // Sole
      final sole = Rect.fromCenter(center: Offset(fx, fy), width: 22 * s, height: 36 * s);
      c.drawRRect(RRect.fromRectAndRadius(sole, Radius.circular(8 * s)), Paint()..color = _pri);
      c.drawRRect(RRect.fromRectAndRadius(sole, Radius.circular(8 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
      // Toes (3 dots)
      final toeY = fy - 15 * s;
      c.drawCircle(Offset(fx - 5 * s * dir, toeY - 4 * s), 3 * s, Paint()..color = _drk);
      c.drawCircle(Offset(fx, toeY - 6 * s), 3 * s, Paint()..color = _drk);
      c.drawCircle(Offset(fx + 5 * s * dir, toeY - 4 * s), 3 * s, Paint()..color = _drk);
    }
    // First footprint (left, slightly rotated)
    c.save();
    c.translate(cx - 18 * s, cy + 3 * s);
    c.rotate(-15 * math.pi / 180);
    drawFootprint(0, 0, 1);
    c.restore();
    // Second footprint (right, ahead)
    c.save();
    c.translate(cx + 18 * s, cy - 12 * s);
    c.rotate(10 * math.pi / 180);
    drawFootprint(0, 0, 1);
    c.restore();
    // Third footprint (further left)
    c.save();
    c.translate(cx - 10 * s, cy - 30 * s);
    c.rotate(-5 * math.pi / 180);
    drawFootprint(0, 0, 1);
    c.restore();
    _drawN(c, cx, cy + 48 * s, r * 0.4);
  }

  // ── 500: Jefe de asuntos operativos ── corona ─────────────────
  void _drawCommand(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 68 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Crown base
    final base = Rect.fromCenter(center: Offset(cx, cy + 18 * s), width: 75 * s, height: 25 * s);
    c.drawRRect(RRect.fromRectAndRadius(base, Radius.circular(5 * s)), Paint()..color = _acc);
    c.drawRRect(RRect.fromRectAndRadius(base, Radius.circular(5 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Crown prongs (3 points)
    final prongs = Path()
      ..moveTo(cx - 32 * s, cy + 6 * s)
      ..lineTo(cx - 28 * s, cy - 30 * s)
      ..lineTo(cx - 14 * s, cy - 8 * s)
      ..lineTo(cx, cy - 40 * s)
      ..lineTo(cx + 14 * s, cy - 8 * s)
      ..lineTo(cx + 28 * s, cy - 30 * s)
      ..lineTo(cx + 32 * s, cy + 6 * s)
      ..close();
    c.drawPath(prongs, Paint()..color = _acc);
    c.drawPath(prongs, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Jewels on prong tips
    c.drawCircle(Offset(cx - 28 * s, cy - 30 * s), 4 * s, Paint()..color = _sec);
    c.drawCircle(Offset(cx, cy - 40 * s), 5 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx + 28 * s, cy - 30 * s), 4 * s, Paint()..color = _sec);
    // Jewels on base
    c.drawCircle(Offset(cx - 18 * s, cy + 18 * s), 4 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy + 18 * s), 4 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx + 18 * s, cy + 18 * s), 4 * s, Paint()..color = _pri);
    _drawN(c, cx, cy + 48 * s, r * 0.4);
  }

  // ── 530: Comisionado de Élite ── diamond badge ──────────────────────
  void _drawDiamond(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final diamond = Path()
      ..moveTo(cx, cy - 85 * s)
      ..lineTo(cx + 70 * s, cy)
      ..lineTo(cx, cy + 85 * s)
      ..lineTo(cx - 70 * s, cy)
      ..close();
    c.drawPath(diamond, Paint()..color = _pri);
    c.drawPath(diamond, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    final inner = Path()
      ..moveTo(cx, cy - 55 * s)
      ..lineTo(cx + 45 * s, cy)
      ..lineTo(cx, cy + 55 * s)
      ..lineTo(cx - 45 * s, cy)
      ..close();
    c.drawPath(inner, Paint()..color = _wht);
    c.drawPath(inner, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? 22 * s : 9 * s;
      star.lineTo(cx + rad * math.cos(a), cy + rad * math.sin(a));
      if (i == 0) { star.moveTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy, r * 0.35);
  }

  // ── 565: Guardián Supremo ── crown badge ───────────────────────────
  void _drawCrown(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy + 10 * s), 72 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy + 10 * s), 72 * s, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    c.drawCircle(Offset(cx, cy + 10 * s), 54 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy + 10 * s), 54 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Crown points
    final crown = Path()
      ..moveTo(cx - 45 * s, cy + 40 * s)
      ..lineTo(cx - 35 * s, cy - 30 * s)
      ..lineTo(cx - 12 * s, cy - 5 * s)
      ..lineTo(cx, cy - 45 * s)
      ..lineTo(cx + 12 * s, cy - 5 * s)
      ..lineTo(cx + 35 * s, cy - 30 * s)
      ..lineTo(cx + 45 * s, cy + 40 * s)
      ..close();
    c.drawPath(crown, Paint()..color = _acc);
    c.drawPath(crown, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy - 5 * s), 8 * s, Paint()..color = _pri);
    _drawN(c, cx, cy + 45 * s, r * 0.35);
  }

  // ── 605: Maestro Consumado ── gem / faceted badge ─────────────────
  void _drawGem(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    final gem = Path()
      ..moveTo(cx, cy - 80 * s)
      ..lineTo(cx + 60 * s, cy - 30 * s)
      ..lineTo(cx + 70 * s, cy + 35 * s)
      ..lineTo(cx, cy + 85 * s)
      ..lineTo(cx - 70 * s, cy + 35 * s)
      ..lineTo(cx - 60 * s, cy - 30 * s)
      ..close();
    c.drawPath(gem, Paint()..color = _sec);
    c.drawPath(gem, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    final facetV = Path()
      ..moveTo(cx, cy - 80 * s)
      ..lineTo(cx, cy + 85 * s);
    c.drawPath(facetV, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    final facetH = Path()
      ..moveTo(cx - 65 * s, cy)
      ..lineTo(cx + 65 * s, cy);
    c.drawPath(facetH, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? 25 * s : 10 * s;
      if (i == 0) { star.moveTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
      else { star.lineTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy, r * 0.35);
  }

  // ── 650: Leyenda Viviente ── sunburst star ────────────────────────
  void _drawSunburst(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Outer ring
    c.drawCircle(Offset(cx, cy), 75 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy), 75 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    c.drawCircle(Offset(cx, cy), 58 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy), 58 * s, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy), 42 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 42 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Sun rays (12 lines)
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final inner = 48 * s;
      final outer = 72 * s;
      c.drawLine(
        Offset(cx + inner * math.cos(a), cy + inner * math.sin(a)),
        Offset(cx + outer * math.cos(a), cy + outer * math.sin(a)),
        Paint()..color = _acc..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round,
      );
    }
    c.drawCircle(Offset(cx, cy), 10 * s, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy), 10 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy, r * 0.3);
  }

  // ── 700: Emblema de Honor ── shield with wings ────────────────────
  void _drawWings(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Shield
    final shield = Path()
      ..moveTo(cx, cy - 75 * s)
      ..lineTo(cx + 60 * s, cy - 40 * s)
      ..lineTo(cx + 60 * s, cy + 20 * s)
      ..cubicTo(cx + 60 * s, cy + 52 * s, cx, cy + 78 * s, cx, cy + 78 * s)
      ..cubicTo(cx, cy + 78 * s, cx - 60 * s, cy + 52 * s, cx - 60 * s, cy + 20 * s)
      ..lineTo(cx - 60 * s, cy - 40 * s)
      ..close();
    c.drawPath(shield, Paint()..color = _pri);
    c.drawPath(shield, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    // Wings
    final wingL = Path()
      ..moveTo(cx - 55 * s, cy - 20 * s)
      ..cubicTo(cx - 85 * s, cy - 60 * s, cx - 75 * s, cy - 70 * s, cx - 45 * s, cy - 55 * s);
    c.drawPath(wingL, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
    final wingR = Path()
      ..moveTo(cx + 55 * s, cy - 20 * s)
      ..cubicTo(cx + 85 * s, cy - 60 * s, cx + 75 * s, cy - 70 * s, cx + 45 * s, cy - 55 * s);
    c.drawPath(wingR, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
    // Inner star
    final inner = Path()
      ..moveTo(cx, cy - 52 * s)
      ..lineTo(cx + 35 * s, cy - 28 * s)
      ..lineTo(cx + 35 * s, cy + 15 * s)
      ..cubicTo(cx + 35 * s, cy + 35 * s, cx, cy + 50 * s, cx, cy + 50 * s)
      ..cubicTo(cx, cy + 50 * s, cx - 35 * s, cy + 35 * s, cx - 35 * s, cy + 15 * s)
      ..lineTo(cx - 35 * s, cy - 28 * s)
      ..close();
    c.drawPath(inner, Paint()..color = _wht);
    c.drawPath(inner, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? 18 * s : 7 * s;
      if (i == 0) { star.moveTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
      else { star.lineTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy + 30 * s, r * 0.35);
  }

  // ── 755: Custodio del Sistema ── pedestal / guardian ─────────────
  void _drawPedestal(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    // Top circle
    c.drawCircle(Offset(cx, cy - 20 * s), 52 * s, Paint()..color = _sec);
    c.drawCircle(Offset(cx, cy - 20 * s), 52 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    c.drawCircle(Offset(cx, cy - 20 * s), 38 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - 20 * s), 38 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    c.drawCircle(Offset(cx, cy - 20 * s), 22 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy - 20 * s), 22 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Pedestal base
    final base = Rect.fromCenter(center: Offset(cx, cy + 45 * s), width: 90 * s, height: 14 * s);
    c.drawRRect(RRect.fromRectAndRadius(base, Radius.circular(5 * s)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(base, Radius.circular(5 * s)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    final pillar = Rect.fromCenter(center: Offset(cx, cy + 20 * s), width: 24 * s, height: 40 * s);
    c.drawRect(pillar, Paint()..color = _pri);
    c.drawRect(pillar, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Laurel
    final branchL = Path()
      ..moveTo(cx - 65 * s, cy - 45 * s)
      ..cubicTo(cx - 50 * s, cy - 65 * s, cx - 25 * s, cy - 50 * s, cx - 25 * s, cy - 45 * s);
    c.drawPath(branchL, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    final branchR = Path()
      ..moveTo(cx + 65 * s, cy - 45 * s)
      ..cubicTo(cx + 50 * s, cy - 65 * s, cx + 25 * s, cy - 50 * s, cx + 25 * s, cy - 45 * s);
    c.drawPath(branchR, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? 14 * s : 6 * s;
      if (i == 0) { star.moveTo(cx + rad * math.cos(a), cy - 20 * s + rad * math.sin(a)); }
      else { star.lineTo(cx + rad * math.cos(a), cy - 20 * s + rad * math.sin(a)); }
    }
    star.close();
    c.drawPath(star, Paint()..color = _acc);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    _drawN(c, cx, cy + 55 * s, r * 0.3);
  }

  // ── 800: Pináculo del Mérito ── grand star ───────────────────────
  void _drawGrandStar(Canvas c, double cx, double cy, double r) {
    final s = r / 100;
    c.drawCircle(Offset(cx, cy), 80 * s, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy), 80 * s, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 3.5 * s);
    c.drawCircle(Offset(cx, cy), 64 * s, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 3 * s);
    c.drawCircle(Offset(cx, cy), 48 * s, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), 48 * s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5 * s);
    // Large 10-point star
    final starO = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? 38 * s : 15 * s;
      if (i == 0) { starO.moveTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
      else { starO.lineTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
    }
    starO.close();
    c.drawPath(starO, Paint()..color = _pri);
    c.drawPath(starO, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2 * s);
    // Small inner star
    final starI = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? 20 * s : 8 * s;
      if (i == 0) { starI.moveTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
      else { starI.lineTo(cx + rad * math.cos(a), cy + rad * math.sin(a)); }
    }
    starI.close();
    c.drawPath(starI, Paint()..color = _acc);
    c.drawPath(starI, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5 * s);
    // Laurel
    final laurelL = Path()
      ..moveTo(cx - 65 * s, cy - 55 * s)
      ..cubicTo(cx - 40 * s, cy - 75 * s, cx - 20 * s, cy - 60 * s, cx - 20 * s, cy - 50 * s);
    c.drawPath(laurelL, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
    final laurelR = Path()
      ..moveTo(cx + 65 * s, cy - 55 * s)
      ..cubicTo(cx + 40 * s, cy - 75 * s, cx + 20 * s, cy - 60 * s, cx + 20 * s, cy - 50 * s);
    c.drawPath(laurelR, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = 3 * s..strokeCap = StrokeCap.round);
    // Ribbon
    final ribbon = Path()
      ..moveTo(cx - 50 * s, cy + 55 * s)
      ..cubicTo(cx - 25 * s, cy + 70 * s, cx, cy + 55 * s, cx, cy + 55 * s)
      ..cubicTo(cx, cy + 55 * s, cx + 25 * s, cy + 70 * s, cx + 50 * s, cy + 55 * s);
    c.drawPath(ribbon, Paint()..color = _sec..style = PaintingStyle.stroke..strokeWidth = 2.5 * s..strokeCap = StrokeCap.round);
    _drawN(c, cx, cy, r * 0.25);
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
