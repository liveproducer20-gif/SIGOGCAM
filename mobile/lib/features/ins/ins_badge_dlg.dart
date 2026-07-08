import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/thm/app_thm.dart';
import 'ins_icn_wdg.dart';
import 'ins_mdl.dart';

class BadgeUnlockDialog extends StatefulWidget {
  final InsigniaDesbloqueadaMdl insignia;

  const BadgeUnlockDialog({super.key, required this.insignia});

  @override
  State<BadgeUnlockDialog> createState() => _BadgeUnlockDialogState();
}

class _BadgeUnlockDialogState extends State<BadgeUnlockDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rotateAnim;
  late final Animation<double> _shineAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 10),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _rotateAnim = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );

    _shineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = int.tryParse(widget.insignia.icono) ?? 0;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotateAnim.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildShine(),
                    Transform.scale(
                      scale: _scaleAnim.value,
                      child: BadgeIcon(
                        metaCartillas: meta,
                        size: 90,
                        unlocked: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Felicidades!',
                  style: TextStyle(
                    color: AppThm.accClr,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.insignia.titulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.insignia.mensaje,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppThm.txtClr.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }

  Widget _buildShine() {
    return AnimatedBuilder(
      animation: _shineAnim,
      builder: (context, _) {
        if (_shineAnim.value <= 0) return const SizedBox();
        return CustomPaint(
          size: const Size(140, 140),
          painter: _ShinePainter(progress: _shineAnim.value),
        );
      },
    );
  }
}

class _ShinePainter extends CustomPainter {
  final double progress;

  _ShinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy);

    final paint = Paint()
      ..color = AppThm.accClr.withValues(alpha: (1.0 - progress) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6 + progress * math.pi * 2;
      final len = r * (0.6 + progress * 0.3);
      final x1 = cx + r * 0.5 * math.cos(angle);
      final y1 = cy + r * 0.5 * math.sin(angle);
      final x2 = cx + len * math.cos(angle);
      final y2 = cy + len * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
