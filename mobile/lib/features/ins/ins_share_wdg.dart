import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

import 'ins_mdl.dart';

class InsShareWdg extends StatefulWidget {
  final InsMdl insignia;
  final String nombreUsuario;

  const InsShareWdg({
    super.key,
    required this.insignia,
    required this.nombreUsuario,
  });

  @override
  State<InsShareWdg> createState() => _InsShareWdgState();
}

class _InsShareWdgState extends State<InsShareWdg> {
  final _repaintKey = GlobalKey();
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Compartir insignia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _repaintKey,
            child: _buildShareCard(),
          ),
          const SizedBox(height: 20),
          if (_generating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else
            FilledButton.icon(
              onPressed: _generating ? null : _generarYCompartir,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartir en mis redes'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _buildShareCard() {
    final meta = widget.insignia.metaCartillas;
    return Container(
      width: 380,
      height: 560,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D3F73), Color(0xFF00A6D6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(380, 560),
              painter: _ConfettiPainter(),
            ),
            Center(
              child: Container(
                width: 340,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/img/logo_segura.png', height: 44, fit: BoxFit.contain),
                    const SizedBox(height: 6),
                    const Text(
                      'Cuerpo de Agentes de Control Municipal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1D3F73),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'SIGO-GCAM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF00A6D6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CustomPaint(
                        painter: _ShareIconPainter(metaCartillas: meta),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.nombreUsuario,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.insignia.titulo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1D3F73),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC400).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFC400).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Por haber completado $meta cartillas.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFC400), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '¡Felicidades!',
                          style: TextStyle(
                            color: const Color(0xFF00A6D6),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF00A6D6).withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star, color: Color(0xFFFFC400), size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Icon(Icons.star, color: const Color(0xFFFFC400).withValues(alpha: 0.4), size: 28),
            ),
            Positioned(
              top: 16,
              right: 18,
              child: Icon(Icons.star, color: Colors.white.withValues(alpha: 0.3), size: 20),
            ),
            Positioned(
              bottom: 14,
              left: 20,
              child: Icon(Icons.star, color: Colors.white.withValues(alpha: 0.25), size: 22),
            ),
            Positioned(
              bottom: 10,
              right: 14,
              child: Icon(Icons.star, color: const Color(0xFFFFC400).withValues(alpha: 0.35), size: 30),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generarYCompartir() async {
    setState(() => _generating = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('No se pudo capturar la imagen');

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('No se pudo generar la imagen');

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/insignia_${widget.insignia.id}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'He desbloqueado "${widget.insignia.titulo}" en SIGO-GCAM',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final colors = [
      const Color(0xFFFFC400),
      Colors.white.withValues(alpha: 0.6),
      const Color(0xFFFFD700),
      const Color(0xFF00A6D6).withValues(alpha: 0.5),
      const Color(0xFF1D3F73).withValues(alpha: 0.3),
    ];

    for (int i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final s = 3 + rng.nextDouble() * 8;
      final color = colors[i % colors.length];
      final shape = rng.nextInt(3);

      if (shape == 0) {
        canvas.drawCircle(Offset(x, y), s, Paint()..color = color);
      } else if (shape == 1) {
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: s, height: s * 0.6), Paint()..color = color);
      } else {
        final a = rng.nextDouble() * math.pi;
        canvas.drawLine(
          Offset(x - s * math.cos(a), y - s * math.sin(a)),
          Offset(x + s * math.cos(a), y + s * math.sin(a)),
          Paint()..color = color..strokeWidth = 1.5..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShareIconPainter extends CustomPainter {
  final int metaCartillas;

  _ShareIconPainter({required this.metaCartillas});

  Color get _pri => const Color(0xFF1D3F73);
  Color get _sec => const Color(0xFF00A6D6);
  Color get _acc => const Color(0xFFFFC400);
  Color get _drk => Colors.black87;
  Color get _wht => Colors.white;

  @override
  void paint(Canvas c, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.85;

    switch (metaCartillas) {
      case 5: _shield(c, cx, cy, r);
      case 10: _pen(c, cx, cy, r);
      case 15: _notepad(c, cx, cy, r);
      case 20: _radio(c, cx, cy, r);
      case 25: _camera(c, cx, cy, r);
      case 30: _whistle(c, cx, cy, r);
      case 35: _magnifier(c, cx, cy, r);
      case 40: _compass(c, cx, cy, r);
      case 45: _starBadge(c, cx, cy, r);
      case 50: _sheriff(c, cx, cy, r);
      case 60: _briefcase(c, cx, cy, r);
      case 70: _clipboard(c, cx, cy, r);
      case 80: _tower(c, cx, cy, r);
      case 90: _scroll(c, cx, cy, r);
      case 100: _laurel(c, cx, cy, r);
      case 110: _agent(c, cx, cy, r);
      case 120: _papamike(c, cx, cy, r);
      case 130: _crazy(c, cx, cy, r);
      case 140: _shark(c, cx, cy, r);
      default: _shield(c, cx, cy, r);
    }
  }

  void _shield(Canvas c, double cx, double cy, double r) {
    final p = Path()..moveTo(cx, cy - r)..lineTo(cx + r * 0.8, cy - r * 0.55)..lineTo(cx + r * 0.8, cy + r * 0.3)..cubicTo(cx + r * 0.8, cy + r * 0.65, cx, cy + r * 0.9, cx, cy + r * 0.9)..cubicTo(cx, cy + r * 0.9, cx - r * 0.8, cy + r * 0.65, cx - r * 0.8, cy + r * 0.3)..lineTo(cx - r * 0.8, cy - r * 0.55)..close();
    c.drawPath(p, Paint()..color = const Color(0xFFCD7F32)..style = PaintingStyle.fill);
    c.drawPath(p, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    _num(c, cx, cy, r * 0.55);
  }
  void _pen(Canvas c, double cx, double cy, double r) {
    final a = -math.pi / 4;
    final len = r * 0.85;
    c.drawLine(Offset(cx + len * math.cos(a), cy + len * math.sin(a)), Offset(cx - len * math.cos(a), cy - len * math.sin(a)), Paint()..color = const Color(0xFFCD7F32)..strokeWidth = r * 0.35..strokeCap = StrokeCap.round);
    c.drawLine(Offset(cx + len * math.cos(a), cy + len * math.sin(a)), Offset(cx - len * math.cos(a), cy - len * math.sin(a)), Paint()..color = _wht..strokeWidth = r * 0.15);
    c.drawCircle(Offset(cx + r * 0.12 * math.cos(a + math.pi), cy + r * 0.12 * math.sin(a + math.pi)), r * 0.06, Paint()..color = _drk);
    _num(c, cx, cy, r * 0.45);
  }
  void _notepad(Canvas c, double cx, double cy, double r) {
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.2, height: r * 1.4);
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.06)), Paint()..color = const Color(0xFFCD7F32));
    c.drawRRect(RRect.fromRectAndRadius(rect.deflate(3), Radius.circular(r * 0.04)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(rect.deflate(3), Radius.circular(r * 0.04)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int i = 0; i < 4; i++) { c.drawLine(Offset(cx - r * 0.4, cy - r * 0.35 + i * r * 0.25), Offset(cx + r * 0.4, cy - r * 0.35 + i * r * 0.25), Paint()..color = _drk..strokeWidth = 1.2); }
    _num(c, cx, cy, r * 0.5);
  }
  void _radio(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy + r * 0.05), width: r * 1.1, height: r * 0.65);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.08)), Paint()..color = const Color(0xFFA0A0A0));
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.08)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawRRect(RRect.fromRectAndRadius(body.deflate(3), Radius.circular(r * 0.06)), Paint()..color = _wht..style = PaintingStyle.stroke..strokeWidth = 1);
    c.drawLine(Offset(cx, cy - r * 0.27), Offset(cx, cy - r * 0.7), Paint()..color = _drk..strokeWidth = 2.5);
    c.drawLine(Offset(cx, cy - r * 0.7), Offset(cx + r * 0.25, cy - r * 0.8), Paint()..color = _drk..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy - r * 0.7), r * 0.04, Paint()..color = _acc);
    _num(c, cx, cy + r * 0.1, r * 0.4);
  }
  void _camera(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.4, height: r * 0.9);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.06)), Paint()..color = const Color(0xFFA0A0A0));
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.06)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final top = Rect.fromCenter(center: Offset(cx + r * 0.1, cy - r * 0.35), width: r * 0.45, height: r * 0.13);
    c.drawRRect(RRect.fromRectAndRadius(top, Radius.circular(2)), Paint()..color = _drk);
    c.drawCircle(Offset(cx - r * 0.12, cy), r * 0.22, Paint()..color = _wht);
    c.drawCircle(Offset(cx - r * 0.12, cy), r * 0.22, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawCircle(Offset(cx - r * 0.12, cy), r * 0.1, Paint()..color = _drk);
    c.drawCircle(Offset(cx - r * 0.12, cy), r * 0.05, Paint()..color = _acc);
    _num(c, cx + r * 0.15, cy + r * 0.1, r * 0.3);
  }
  void _whistle(Canvas c, double cx, double cy, double r) {
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 0.6, height: r * 0.6), Paint()..color = const Color(0xFFA0A0A0));
    c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 0.6, height: r * 0.6), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final m = Path()..moveTo(cx + r * 0.3, cy - r * 0.15)..lineTo(cx + r * 0.75, cy - r * 0.3)..lineTo(cx + r * 0.75, cy + r * 0.15)..lineTo(cx + r * 0.3, cy + r * 0.15)..close();
    c.drawPath(m, Paint()..color = const Color(0xFFA0A0A0)..style = PaintingStyle.fill);
    c.drawPath(m, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _num(c, cx, cy + r * 0.35, r * 0.35);
  }
  void _magnifier(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx - r * 0.08, cy - r * 0.08), r * 0.4, Paint()..color = const Color(0xFFFFD700));
    c.drawCircle(Offset(cx - r * 0.08, cy - r * 0.08), r * 0.4, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx - r * 0.08, cy - r * 0.08), r * 0.28, Paint()..color = _acc);
    c.drawCircle(Offset(cx - r * 0.08, cy - r * 0.08), r * 0.28, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawLine(Offset(cx + r * 0.2, cy + r * 0.2), Offset(cx + r * 0.65, cy + r * 0.65), Paint()..color = _drk..strokeWidth = r * 0.1..strokeCap = StrokeCap.round);
    _num(c, cx + r * 0.15, cy + r * 0.45, r * 0.3);
  }
  void _compass(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.7, Paint()..color = const Color(0xFFFFD700));
    c.drawCircle(Offset(cx, cy), r * 0.7, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy), r * 0.5, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), r * 0.5, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawLine(Offset(cx, cy - r * 0.45), Offset(cx, cy + r * 0.45), Paint()..color = _drk..strokeWidth = 1.5);
    c.drawLine(Offset(cx - r * 0.45, cy), Offset(cx + r * 0.45, cy), Paint()..color = _drk..strokeWidth = 1.5);
    final t = Path()..moveTo(cx, cy - r * 0.35)..lineTo(cx - r * 0.1, cy + r * 0.03)..lineTo(cx + r * 0.1, cy + r * 0.03)..close();
    c.drawPath(t, Paint()..color = _acc);
    _num(c, cx, cy + r * 0.05, r * 0.3);
  }
  void _starBadge(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.75, Paint()..color = const Color(0xFFFFD700));
    c.drawCircle(Offset(cx, cy), r * 0.75, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), r * 0.55, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final s = Path();
    for (int i = 0; i < 10; i++) { final a = -math.pi / 2 + i * math.pi / 5; final rad = i.isEven ? r * 0.45 : r * 0.2; final x = cx + rad * math.cos(a); final y = cy + rad * math.sin(a); if (i == 0) { s.moveTo(x, y); } else { s.lineTo(x, y); } }
    s.close();
    c.drawPath(s, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill);
    c.drawPath(s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    _num(c, cx, cy, r * 0.3);
  }
  void _sheriff(Canvas c, double cx, double cy, double r) {
    final s = Path();
    for (int i = 0; i < 12; i++) { final a = -math.pi / 2 + i * math.pi / 6; final rad = i.isEven ? r * 0.75 : r * 0.3; final x = cx + rad * math.cos(a); final y = cy + rad * math.sin(a); if (i == 0) { s.moveTo(x, y); } else { s.lineTo(x, y); } }
    s.close();
    c.drawPath(s, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill);
    c.drawPath(s, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy), r * 0.22, Paint()..color = _acc);
    c.drawCircle(Offset(cx, cy), r * 0.22, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _num(c, cx, cy, r * 0.25);
  }
  void _briefcase(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy + r * 0.05), width: r * 1.2, height: r * 0.8);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.05)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.05)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final h = Rect.fromCenter(center: Offset(cx, cy - r * 0.35), width: r * 0.45, height: r * 0.18);
    c.drawRRect(RRect.fromRectAndRadius(h, Radius.circular(r * 0.05)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(h, Radius.circular(r * 0.05)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawLine(Offset(cx - r * 0.08, cy + r * 0.05), Offset(cx + r * 0.08, cy + r * 0.05), Paint()..color = _acc..strokeWidth = r * 0.05..strokeCap = StrokeCap.round);
    _num(c, cx, cy + r * 0.35, r * 0.3);
  }
  void _clipboard(Canvas c, double cx, double cy, double r) {
    final body = Rect.fromCenter(center: Offset(cx, cy + r * 0.05), width: r * 0.9, height: r * 1.1);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.04)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.04)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawRRect(RRect.fromRectAndRadius(body.deflate(3), Radius.circular(r * 0.03)), Paint()..color = _wht);
    for (int i = 0; i < 4; i++) { c.drawLine(Offset(cx - r * 0.3, cy - r * 0.3 + i * r * 0.22), Offset(cx + r * 0.3, cy - r * 0.3 + i * r * 0.22), Paint()..color = _drk..strokeWidth = 1); }
    final stamp = Rect.fromCenter(center: Offset(cx + r * 0.25, cy + r * 0.28), width: r * 0.16, height: r * 0.16);
    c.drawRRect(RRect.fromRectAndRadius(stamp, Radius.circular(2)), Paint()..color = _acc);
    _num(c, cx, cy + r * 0.08, r * 0.35);
  }
  void _tower(Canvas c, double cx, double cy, double r) {
    final base = Rect.fromCenter(center: Offset(cx, cy + r * 0.18), width: r * 0.65, height: r * 0.65);
    c.drawRect(base, Paint()..color = _sec);
    c.drawRect(base, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final roof = Path()..moveTo(cx - r * 0.45, cy - r * 0.28)..lineTo(cx, cy - r * 0.8)..lineTo(cx + r * 0.45, cy - r * 0.28)..close();
    c.drawPath(roof, Paint()..color = _pri);
    c.drawPath(roof, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final win = Rect.fromCenter(center: Offset(cx, cy), width: r * 0.18, height: r * 0.22);
    c.drawRRect(RRect.fromRectAndRadius(win, Radius.circular(2)), Paint()..color = _acc);
    c.drawRRect(RRect.fromRectAndRadius(win, Radius.circular(2)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1);
    _num(c, cx, cy + r * 0.5, r * 0.3);
  }
  void _scroll(Canvas c, double cx, double cy, double r) {
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 1.0, height: r * 1.2);
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.05)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.05)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawRRect(RRect.fromRectAndRadius(rect.deflate(3), Radius.circular(r * 0.03)), Paint()..color = const Color(0xFFFFF8E7));
    final tr = Rect.fromCenter(center: Offset(cx, cy - r * 0.5), width: r * 1.2, height: r * 0.12);
    c.drawRRect(RRect.fromRectAndRadius(tr, Radius.circular(r * 0.06)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(tr, Radius.circular(r * 0.06)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final br = Rect.fromCenter(center: Offset(cx, cy + r * 0.5), width: r * 1.2, height: r * 0.12);
    c.drawRRect(RRect.fromRectAndRadius(br, Radius.circular(r * 0.06)), Paint()..color = _sec);
    c.drawRRect(RRect.fromRectAndRadius(br, Radius.circular(r * 0.06)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int i = 0; i < 3; i++) { c.drawLine(Offset(cx - r * 0.35, cy - r * 0.25 + i * r * 0.25), Offset(cx + r * 0.35, cy - r * 0.25 + i * r * 0.25), Paint()..color = _drk..strokeWidth = 1); }
    _num(c, cx, cy, r * 0.35);
  }
  void _laurel(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 0.78, Paint()..color = _pri);
    c.drawCircle(Offset(cx, cy), r * 0.78, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2.5);
    c.drawCircle(Offset(cx, cy), r * 0.6, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy), r * 0.42, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy), r * 0.42, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    for (int i = 0; i < 12; i++) {
      final a = i * 2 * math.pi / 12;
      final li = r * 0.5; final lo = r * 0.72;
      final lx1 = cx + li * math.cos(a), ly1 = cy + li * math.sin(a);
      final lx2 = cx + lo * math.cos(a), ly2 = cy + lo * math.sin(a);
      final mx = cx + (li + lo) / 2 * math.cos(a + 0.06), my = cy + (li + lo) / 2 * math.sin(a + 0.06);
      final leaf = Path()..moveTo(lx1, ly1)..quadraticBezierTo(mx, my, lx2, ly2)..quadraticBezierTo(cx + (li + lo) / 2 * math.cos(a - 0.06), cy + (li + lo) / 2 * math.sin(a - 0.06), lx1, ly1);
      c.drawPath(leaf, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill);
    }
    final star = Path();
    for (int i = 0; i < 10; i++) { final a = -math.pi / 2 + i * math.pi / 5; final rad = i.isEven ? r * 0.25 : r * 0.1; final sx = cx + rad * math.cos(a); final sy = cy + rad * math.sin(a); if (i == 0) { star.moveTo(sx, sy); } else { star.lineTo(sx, sy); } }
    star.close();
    c.drawPath(star, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill);
    _num(c, cx, cy, r * 0.25);
  }
  void _agent(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy - r * 0.18), r * 0.26, Paint()..color = const Color(0xFFFFE0BD));
    c.drawCircle(Offset(cx, cy - r * 0.18), r * 0.26, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    final body = Rect.fromCenter(center: Offset(cx, cy + r * 0.18), width: r * 0.85, height: r * 0.65);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.08)), Paint()..color = _pri);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(r * 0.08)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final half = Rect.fromCenter(center: Offset(cx - r * 0.2, cy + r * 0.18), width: r * 0.42, height: r * 0.65);
    c.drawRRect(RRect.fromRectAndRadius(half, Radius.circular(r * 0.06)), Paint()..color = _sec);
    c.drawCircle(Offset(cx, cy - r * 0.18), r * 0.05, Paint()..color = _drk);
    final hat = Rect.fromCenter(center: Offset(cx, cy - r * 0.42), width: r * 0.45, height: r * 0.08);
    c.drawRRect(RRect.fromRectAndRadius(hat, Radius.circular(2)), Paint()..color = _pri);
    c.drawCircle(Offset(cx - r * 0.18, cy + r * 0.15), r * 0.035, Paint()..color = _acc);
    _num(c, cx + r * 0.05, cy + r * 0.42, r * 0.35);
  }
  void _papamike(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.65, Paint()..color = const Color(0xFFFFD700));
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.65, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 2);
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.48, Paint()..color = _wht);
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.48, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawCircle(Offset(cx, cy - r * 0.05), r * 0.32, Paint()..color = _acc);
    final star = Path();
    for (int i = 0; i < 10; i++) { final a = -math.pi / 2 + i * math.pi / 5; final rad = i.isEven ? r * 0.22 : r * 0.08; final sx = cx + rad * math.cos(a); final sy = cy - r * 0.05 + rad * math.sin(a); if (i == 0) { star.moveTo(sx, sy); } else { star.lineTo(sx, sy); } }
    star.close();
    c.drawPath(star, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill);
    _num(c, cx, cy - r * 0.05, r * 0.28);
  }
  void _crazy(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy - r * 0.22), r * 0.28, Paint()..color = const Color(0xFFFFE0BD));
    c.drawCircle(Offset(cx, cy - r * 0.22), r * 0.28, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int i = 0; i < 8; i++) { final a = i * 2 * math.pi / 8 - math.pi / 2; c.drawLine(Offset(cx + r * 0.26 * math.cos(a), cy - r * 0.22 + r * 0.26 * math.sin(a)), Offset(cx + r * 0.5 * math.cos(a), cy - r * 0.5 + r * 0.45 * math.sin(a)), Paint()..color = _drk..strokeWidth = 2..strokeCap = StrokeCap.round); }
    c.drawCircle(Offset(cx - r * 0.07, cy - r * 0.24), r * 0.035, Paint()..color = _drk);
    c.drawCircle(Offset(cx + r * 0.07, cy - r * 0.24), r * 0.035, Paint()..color = _drk);
    final m = Path()..moveTo(cx - r * 0.1, cy - r * 0.06)..lineTo(cx - r * 0.16, cy + r * 0.02)..lineTo(cx - r * 0.06, cy + r * 0.04)..lineTo(cx, cy + r * 0.1)..lineTo(cx + r * 0.06, cy + r * 0.04)..lineTo(cx + r * 0.16, cy + r * 0.02)..lineTo(cx + r * 0.1, cy - r * 0.06)..close();
    c.drawPath(m, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final cl = Rect.fromCenter(center: Offset(cx, cy + r * 0.38), width: r * 0.5, height: r * 0.45);
    c.drawRRect(RRect.fromRectAndRadius(cl, Radius.circular(3)), Paint()..color = _wht);
    c.drawRRect(RRect.fromRectAndRadius(cl, Radius.circular(3)), Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _num(c, cx, cy + r * 0.42, r * 0.2);
  }
  void _shark(Canvas c, double cx, double cy, double r) {
    final body = Path()..moveTo(cx - r * 0.65, cy)..cubicTo(cx - r * 0.65, cy - r * 0.45, cx + r * 0.45, cy - r * 0.5, cx + r * 0.65, cy - r * 0.22)..lineTo(cx + r * 0.7, cy - r * 0.08)..lineTo(cx + r * 0.85, cy - r * 0.08)..lineTo(cx + r * 0.85, cy + r * 0.08)..lineTo(cx + r * 0.7, cy + r * 0.08)..lineTo(cx + r * 0.65, cy + r * 0.22)..cubicTo(cx + r * 0.45, cy + r * 0.5, cx - r * 0.65, cy + r * 0.45, cx - r * 0.65, cy)..close();
    c.drawPath(body, Paint()..color = _sec);
    c.drawPath(body, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final d = Path()..moveTo(cx + r * 0.1, cy - r * 0.4)..lineTo(cx + r * 0.25, cy - r * 0.72)..lineTo(cx + r * 0.4, cy - r * 0.4)..close();
    c.drawPath(d, Paint()..color = _pri);
    c.drawPath(d, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    final t = Path()..moveTo(cx - r * 0.65, cy)..lineTo(cx - r * 0.78, cy - r * 0.25)..lineTo(cx - r * 0.65, cy - r * 0.08)..lineTo(cx - r * 0.78, cy + r * 0.25)..close();
    c.drawPath(t, Paint()..color = _pri);
    c.drawPath(t, Paint()..color = _drk..style = PaintingStyle.stroke..strokeWidth = 1.5);
    c.drawCircle(Offset(cx + r * 0.15, cy - r * 0.02), r * 0.04, Paint()..color = _drk);
    _num(c, cx - r * 0.05, cy + r * 0.15, r * 0.3);
  }
  void _num(Canvas c, double cx, double cy, double s) {
    final t = '$metaCartillas';
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(color: _drk, fontSize: s * 0.55, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr, textAlign: TextAlign.center,
    )..layout();
    tp.paint(c, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ShareIconPainter oldDelegate) => oldDelegate.metaCartillas != metaCartillas;
}
