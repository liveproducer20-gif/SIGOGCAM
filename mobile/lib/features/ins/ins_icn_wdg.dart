import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'badge_catalog.dart';
import 'ins_achievement_theme.dart';

class BadgeIcon extends StatelessWidget {
  final int metaCartillas;
  final double size;
  final bool unlocked;
  final int? nivel;

  const BadgeIcon({
    super.key,
    required this.metaCartillas,
    this.size = 68,
    this.unlocked = true,
    this.nivel,
  });

  @override
  Widget build(BuildContext context) {
    final badge = BadgeCatalog.byMeta(metaCartillas);
    final lvl = nivel ?? badge?.nivel ?? 1;
    final theme = LevelTheme.forNivel(lvl);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BadgePainter(
          metaCartillas: metaCartillas,
          unlocked: unlocked,
          nivel: lvl,
          theme: theme,
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  final int metaCartillas;
  final bool unlocked;
  final int nivel;
  final LevelTheme theme;

  _BadgePainter({
    required this.metaCartillas,
    required this.unlocked,
    required this.nivel,
    required this.theme,
  });

  Color get _hexBg => unlocked ? theme.primaryColor : Colors.grey.shade400;
  Color get _hexBorder => unlocked ? theme.accentColor : Colors.grey.shade300;
  Color get _iconColor => unlocked ? Colors.white : Colors.grey.shade200;
  Color get _numColor => unlocked ? theme.accentColor : Colors.grey.shade400;
  Color get _drk => unlocked ? Colors.black87 : Colors.grey.shade500;
  Color get _acc => unlocked ? const Color(0xFFFFC400) : Colors.grey.shade400;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.95;

    // Draw hexagon background
    _drawHexagon(canvas, cx, cy, r);
    // Draw inner icon
    _drawLevelIcon(canvas, cx, cy, r * 0.65);
    // Draw badge number
    _drawN(canvas, cx, cy + r * 0.55, r * 0.35);
  }

  void _drawHexagon(Canvas c, double cx, double cy, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final x = cx + r * math.cos(a);
      final y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    c.drawPath(path, Paint()..color = _hexBg);
    c.drawPath(path, Paint()
      ..color = _hexBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.06);
  }

  void _drawLevelIcon(Canvas c, double cx, double cy, double r) {
    if (!unlocked) {
      c.drawCircle(Offset(cx, cy), r * 0.3, Paint()..color = Colors.grey.shade300);
      final path = Path();
      const pad = 0.25;
      path.moveTo(cx - r * pad, cy - r * 0.4);
      path.lineTo(cx + r * pad, cy - r * 0.4);
      path.lineTo(cx + r * pad, cy + r * 0.4);
      path.lineTo(cx - r * pad, cy + r * 0.4);
      path.close();
      c.drawPath(path, Paint()..color = Colors.grey.shade100);
      c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.12, Paint()..color = Colors.grey.shade400);
      c.drawCircle(Offset(cx - r * 0.15, cy + r * 0.15), r * 0.06, Paint()..color = Colors.grey.shade400);
      c.drawCircle(Offset(cx + r * 0.15, cy + r * 0.15), r * 0.06, Paint()..color = Colors.grey.shade400);
      return;
    }

    // Level-based generic icons using simple shapes
    switch (nivel) {
      case 1: _drawLevel1Icon(c, cx, cy, r);
      case 2: _drawLevel2Icon(c, cx, cy, r);
      case 3: _drawLevel3Icon(c, cx, cy, r);
      case 4: _drawLevel4Icon(c, cx, cy, r);
      case 5: _drawLevel5Icon(c, cx, cy, r);
      case 6: _drawLevel6Icon(c, cx, cy, r);
      case 7: _drawLevel7Icon(c, cx, cy, r);
      case 8: _drawLevel8Icon(c, cx, cy, r);
      case 9: _drawLevel9Icon(c, cx, cy, r);
      case 10: _drawLevel10Icon(c, cx, cy, r);
      default: _drawLevel1Icon(c, cx, cy, r);
    }
  }

  // N1: Shield
  void _drawLevel1Icon(Canvas c, double cx, double cy, double r) {
    final shield = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.85, cy - r * 0.4)
      ..lineTo(cx + r * 0.85, cy + r * 0.3)
      ..cubicTo(cx + r * 0.85, cy + r * 0.7, cx, cy + r, cx, cy + r)
      ..cubicTo(cx, cy + r, cx - r * 0.85, cy + r * 0.7, cx - r * 0.85, cy + r * 0.3)
      ..lineTo(cx - r * 0.85, cy - r * 0.4)
      ..close();
    c.drawPath(shield, Paint()..color = _iconColor);
    c.drawPath(shield, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = r * 0.06);
    final star = _makeStar(cx, cy, r * 0.3, r * 0.12);
    c.drawPath(star, Paint()..color = _acc);
  }

  // N2: Compass / Direction
  void _drawLevel2Icon(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.7, Paint()..color = _iconColor);
    c.drawCircle(Offset(cx, cy), r * 0.7, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = r * 0.06);
    c.drawCircle(Offset(cx, cy), r * 0.5, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = r * 0.05);
    // Arrow
    final arrow = Path()
      ..moveTo(cx, cy - r * 0.6)
      ..lineTo(cx + r * 0.2, cy + r * 0.1)
      ..lineTo(cx, cy)
      ..lineTo(cx - r * 0.2, cy + r * 0.1)
      ..close();
    c.drawPath(arrow, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy), r * 0.1, Paint()..color = _drk);
  }

  // N3: Star
  void _drawLevel3Icon(Canvas c, double cx, double cy, double r) {
    final star = _makeStar(cx, cy, r * 0.7, r * 0.3);
    c.drawPath(star, Paint()..color = _iconColor);
    c.drawPath(star, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = r * 0.05);
    c.drawCircle(Offset(cx, cy), r * 0.2, Paint()..color = _acc);
  }

  // N4: Diamond
  void _drawLevel4Icon(Canvas c, double cx, double cy, double r) {
    final diamond = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r, cy)
      ..close();
    c.drawPath(diamond, Paint()..color = _iconColor);
    c.drawPath(diamond, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = r * 0.06);
    final inner = Path()
      ..moveTo(cx, cy - r * 0.5)
      ..lineTo(cx + r * 0.5, cy)
      ..lineTo(cx, cy + r * 0.5)
      ..lineTo(cx - r * 0.5, cy)
      ..close();
    c.drawPath(inner, Paint()..color = _acc);
  }

  // N5: Crown
  void _drawLevel5Icon(Canvas c, double cx, double cy, double r) {
    final crown = Path()
      ..moveTo(cx - r * 0.9, cy + r * 0.5)
      ..lineTo(cx - r * 0.7, cy - r * 0.5)
      ..lineTo(cx - r * 0.25, cy - r * 0.1)
      ..lineTo(cx, cy - r * 0.7)
      ..lineTo(cx + r * 0.25, cy - r * 0.1)
      ..lineTo(cx + r * 0.7, cy - r * 0.5)
      ..lineTo(cx + r * 0.9, cy + r * 0.5)
      ..close();
    c.drawPath(crown, Paint()..color = _iconColor);
    c.drawPath(crown, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = r * 0.06);
    c.drawCircle(Offset(cx, cy - r * 0.7), r * 0.1, Paint()..color = _acc);
  }

  // N6: Target / Scope
  void _drawLevel6Icon(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r, Paint()..color = _iconColor);
    c.drawCircle(Offset(cx, cy), r, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = r * 0.06);
    c.drawCircle(Offset(cx, cy), r * 0.6, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = r * 0.05);
    c.drawCircle(Offset(cx, cy), r * 0.3, Paint()..color = _acc);
    c.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), Paint()..color = _drk..strokeWidth = r * 0.04);
    c.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), Paint()..color = _drk..strokeWidth = r * 0.04);
  }

  // N7: Laurel / Wreath
  void _drawLevel7Icon(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.7, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = r * 0.06);
    c.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = _iconColor);
    final branch = Path()
      ..moveTo(cx - r * 0.9, cy - r * 0.1)
      ..cubicTo(cx - r * 0.6, cy - r * 0.8, cx + r * 0.6, cy - r * 0.8, cx + r * 0.9, cy - r * 0.1);
    c.drawPath(branch, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = r * 0.08..strokeCap = StrokeCap.round);
    final star = _makeStar(cx, cy, r * 0.3, r * 0.12);
    c.drawPath(star, Paint()..color = _acc);
  }

  // N8: Wings
  void _drawLevel8Icon(Canvas c, double cx, double cy, double r) {
    final shield = Path()
      ..moveTo(cx, cy - r * 0.6)
      ..lineTo(cx + r * 0.5, cy - r * 0.2)
      ..lineTo(cx + r * 0.5, cy + r * 0.3)
      ..cubicTo(cx + r * 0.5, cy + r * 0.6, cx, cy + r * 0.8, cx, cy + r * 0.8)
      ..cubicTo(cx, cy + r * 0.8, cx - r * 0.5, cy + r * 0.6, cx - r * 0.5, cy + r * 0.3)
      ..lineTo(cx - r * 0.5, cy - r * 0.2)
      ..close();
    c.drawPath(shield, Paint()..color = _iconColor);
    c.drawPath(shield, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = r * 0.05);
    // Wings
    final wingL = Path()
      ..moveTo(cx - r * 0.45, cy)
      ..cubicTo(cx - r * 0.8, cy - r * 0.5, cx - r * 0.7, cy - r * 0.7, cx - r * 0.4, cy - r * 0.55);
    c.drawPath(wingL, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = r * 0.06);
    final wingR = Path()
      ..moveTo(cx + r * 0.45, cy)
      ..cubicTo(cx + r * 0.8, cy - r * 0.5, cx + r * 0.7, cy - r * 0.7, cx + r * 0.4, cy - r * 0.55);
    c.drawPath(wingR, Paint()..color = _acc..style = PaintingStyle.stroke..strokeWidth = r * 0.06);
  }

  // N9: Eye / Vigilance
  void _drawLevel9Icon(Canvas c, double cx, double cy, double r) {
    final eye = Path()
      ..moveTo(cx - r, cy)
      ..cubicTo(cx - r * 0.5, cy - r * 0.8, cx + r * 0.5, cy - r * 0.8, cx + r, cy)
      ..cubicTo(cx + r * 0.5, cy + r * 0.8, cx - r * 0.5, cy + r * 0.8, cx - r, cy)
      ..close();
    c.drawPath(eye, Paint()..color = _iconColor);
    c.drawPath(eye, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = r * 0.06);
    c.drawCircle(Offset(cx, cy), r * 0.35, Paint()..color = _drk);
    c.drawCircle(Offset(cx, cy), r * 0.15, Paint()..color = _iconColor);
    c.drawCircle(Offset(cx, cy), r * 0.08, Paint()..color = _drk);
  }

  // N10: Sunburst / Supreme
  void _drawLevel10Icon(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r, Paint()..color = _iconColor);
    c.drawCircle(Offset(cx, cy), r, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = r * 0.06);
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final inner = r * 0.5;
      final outer = r;
      c.drawLine(
        Offset(cx + inner * math.cos(a), cy + inner * math.sin(a)),
        Offset(cx + outer * math.cos(a), cy + outer * math.sin(a)),
        Paint()..color = _acc..strokeWidth = r * 0.06..strokeCap = StrokeCap.round,
      );
    }
    c.drawCircle(Offset(cx, cy), r * 0.4, Paint()..color = _drk);
    final star = _makeStar(cx, cy, r * 0.3, r * 0.12);
    c.drawPath(star, Paint()..color = _acc);
  }

  Path _makeStar(double cx, double cy, double outer, double inner) {
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? outer : inner;
      if (i == 0) {
        star.moveTo(cx + rad * math.cos(a), cy + rad * math.sin(a));
      } else {
        star.lineTo(cx + rad * math.cos(a), cy + rad * math.sin(a));
      }
    }
    star.close();
    return star;
  }

  void _drawN(Canvas c, double cx, double cy, double s) {
    final t = '$metaCartillas';
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          color: _numColor,
          fontSize: s * 0.65,
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
      oldDelegate.metaCartillas != metaCartillas ||
      oldDelegate.unlocked != unlocked ||
      oldDelegate.nivel != nivel;
}
