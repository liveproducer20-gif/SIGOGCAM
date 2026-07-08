import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

import 'ins_icn_wdg.dart';
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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Compartir insignia',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            RepaintBoundary(
              key: _repaintKey,
              child: _buildShareCard(),
            ),
            const SizedBox(height: 12),
            if (_generating)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.icon(
                  onPressed: _generating ? null : _generarYCompartir,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Compartir en mis redes'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 340,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFF0F7FF),
                        Colors.white,
                        Color(0xFFFFF9E6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _InnerConfettiPainter(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                            BadgeIcon(metaCartillas: meta, size: 80),
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
                    ],
                  ),
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

class _InnerConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final colors = [
      const Color(0xFFFFC400).withValues(alpha: 0.25),
      const Color(0xFF00A6D6).withValues(alpha: 0.15),
      const Color(0xFF1D3F73).withValues(alpha: 0.1),
      const Color(0xFFFFD700).withValues(alpha: 0.2),
    ];

    for (int i = 0; i < 30; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final s = 2 + rng.nextDouble() * 6;
      final color = colors[i % colors.length];
      final shape = rng.nextInt(3);

      if (shape == 0) {
        canvas.drawCircle(Offset(x, y), s, Paint()..color = color);
      } else if (shape == 1) {
        canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: s, height: s * 0.5), Paint()..color = color);
      } else {
        final a = rng.nextDouble() * math.pi;
        canvas.drawLine(
          Offset(x - s * math.cos(a), y - s * math.sin(a)),
          Offset(x + s * math.cos(a), y + s * math.sin(a)),
          Paint()..color = color..strokeWidth = 1..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


