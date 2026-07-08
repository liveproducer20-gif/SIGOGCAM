import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

import '../../core/thm/app_thm.dart';
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
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThm.priClr.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/img/logo_segura.png',
            height: 48,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(
            'Cuerpo de Agentes de Control Municipal',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppThm.priClr,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'SIGO-GCAM',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppThm.secClr,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          _BadgeShareIcon(metaCartillas: meta),
          const SizedBox(height: 12),
          Text(
            widget.nombreUsuario,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppThm.txtClr,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.insignia.titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppThm.priClr,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppThm.accClr.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Por haber completado $meta cartillas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppThm.txtClr,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '¡Felicidades!',
            style: TextStyle(
              color: AppThm.secClr,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
      final file = File(
        '${tempDir.path}/insignia_${widget.insignia.id}.png',
      );
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

class _BadgeShareIcon extends StatelessWidget {
  final int metaCartillas;

  const _BadgeShareIcon({required this.metaCartillas});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _ShareBadgePainter(metaCartillas: metaCartillas),
      ),
    );
  }
}

class _ShareBadgePainter extends CustomPainter {
  final int metaCartillas;

  _ShareBadgePainter({required this.metaCartillas});

  int get _tier {
    if (metaCartillas <= 15) return 1;
    if (metaCartillas <= 30) return 2;
    if (metaCartillas <= 45) return 3;
    if (metaCartillas <= 70) return 4;
    return 5;
  }

  Color get _baseColor {
    switch (_tier) {
      case 1: return const Color(0xFFCD7F32);
      case 2: return const Color(0xFFA0A0A0);
      case 3: return const Color(0xFFFFD700);
      case 4: return const Color(0xFFB0C4DE);
      case 5: return const Color(0xFF4A90D9);
      default: return Colors.grey;
    }
  }

  Color get _innerColor {
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
    final r = math.min(cx, cy) * 0.85;

    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = _baseColor);
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = _baseColor.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(Offset(cx, cy), r * 0.7, Paint()..color = _innerColor);
    canvas.drawCircle(Offset(cx, cy), r * 0.7, Paint()..color = _baseColor..style = PaintingStyle.stroke..strokeWidth = 2);

    final text = '$metaCartillas';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: _baseColor,
          fontSize: r * 0.55,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ShareBadgePainter oldDelegate) =>
      oldDelegate.metaCartillas != metaCartillas;
}
