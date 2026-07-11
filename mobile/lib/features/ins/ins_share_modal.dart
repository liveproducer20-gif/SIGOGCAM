import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

import '../adm/adm_design_tokens.dart';
import 'ins_achievement_theme.dart';
import 'ins_icn_wdg.dart';

/// Opens the share achievement modal.
void showShareAchievement(BuildContext context, {
  required String titulo,
  required String mensaje,
  required int metaCartillas,
  required int totalCartillas,
  required String nombreUsuario,
  String? nivelName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InsShareModal(
      titulo: titulo,
      mensaje: mensaje,
      metaCartillas: metaCartillas,
      totalCartillas: totalCartillas,
      nombreUsuario: nombreUsuario,
      nivelName: nivelName,
    ),
  );
}

class _InsShareModal extends StatefulWidget {
  final String titulo;
  final String mensaje;
  final int metaCartillas;
  final int totalCartillas;
  final String nombreUsuario;
  final String? nivelName;

  const _InsShareModal({
    required this.titulo,
    required this.mensaje,
    required this.metaCartillas,
    required this.totalCartillas,
    required this.nombreUsuario,
    this.nivelName,
  });

  @override
  State<_InsShareModal> createState() => _InsShareModalState();
}

class _InsShareModalState extends State<_InsShareModal> {
  final _repaintKey = GlobalKey();
  bool _generating = false;

  LevelTheme get _theme => LevelTheme.forMeta(widget.metaCartillas);
  int get _total => widget.totalCartillas;
  String get _nivel => widget.nivelName ?? _theme.name;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cardWidth = isMobile ? 300.0 : 360.0;
    final cardHeight = cardWidth * 1350 / 1080; // 4:5 ratio

    return DraggableScrollableSheet(
      initialChildSize: isMobile ? 0.95 : 0.88,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  'Compartir logro',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AdmTokens.grey900,
                  ),
                ),
              ),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Share card preview
                      RepaintBoundary(
                        key: _repaintKey,
                        child: _ShareCard(
                          width: cardWidth,
                          height: cardHeight,
                          titulo: widget.titulo,
                          mensaje: widget.mensaje,
                          metaCartillas: widget.metaCartillas,
                          totalCartillas: widget.totalCartillas,
                          nombreUsuario: widget.nombreUsuario,
                          nivelName: _nivel,
                          theme: _theme,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Action buttons
                      if (_generating)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      else ...[
                        _ActionRow(
                          icon: Icons.copy_rounded,
                          label: 'Copiar texto',
                          color: AdmTokens.primary,
                          onTap: _copyText,
                        ),
                        const SizedBox(height: 10),
                        _ActionRow(
                          icon: Icons.share_rounded,
                          label: 'Compartir',
                          color: const Color(0xFF25D366),
                          onTap: _share,
                        ),
                        const SizedBox(height: 10),
                        _ActionRow(
                          icon: Icons.download_rounded,
                          label: 'Descargar imagen',
                          color: const Color(0xFF8E44AD),
                          onTap: _download,
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Close
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AdmTokens.grey500,
                            side: BorderSide(color: AdmTokens.grey200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Cerrar',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String get _shareText => '🌟 He desbloqueado "${widget.titulo}" en SIGO-GCAM\n\n'
      '🏅 Logro: ${widget.titulo}\n'
      '📄 Cartillas completadas: $_total\n'
      '⭐ Nivel: $_nivel\n\n'
      '📋 ${widget.mensaje}\n\n'
      '🔗 Cuerpo de Agentes de Control Municipal — SIGO-GCAM';

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _shareText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Texto copiado al portapapeles'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _share() async {
    setState(() => _generating = true);
    try {
      final file = await _captureImage();
      if (file == null) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: _shareText,
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

  Future<void> _download() async {
    setState(() => _generating = true);
    try {
      final file = await _captureImage();
      if (file == null) return;
      // Use share sheet which includes "Save to Files" option
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Descarga tu logro de SIGO-GCAM',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<File?> _captureImage() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final boundary =
        _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/insignia_${widget.titulo.replaceAll(RegExp(r'[^\w]'), '_')}.png',
    );
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }
}

// ──────────────────────────────────────────────
// SHARE CARD — 1080×1350 px equivalent (4:5)
// ──────────────────────────────────────────────

class _ShareCard extends StatelessWidget {
  final double width;
  final double height;
  final String titulo;
  final String mensaje;
  final int metaCartillas;
  final int totalCartillas;
  final String nombreUsuario;
  final String nivelName;
  final LevelTheme theme;

  const _ShareCard({
    required this.width,
    required this.height,
    required this.titulo,
    required this.mensaje,
    required this.metaCartillas,
    required this.totalCartillas,
    required this.nombreUsuario,
    required this.nivelName,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final scale = width / 1080;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20 * scale),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D3F73), Color(0xFF00A6D6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20 * scale),
        child: Stack(
          children: [
            CustomPaint(
              size: Size(width, height),
              painter: _CardConfettiPainter(
                primaryColor: theme.primaryColor,
                accentColor: theme.accentColor,
              ),
            ),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14 * scale),
                child: Container(
                  width: width * 0.88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF0F7FF), Colors.white, Color(0xFFFFF9E6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24 * scale,
                      vertical: 28 * scale,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Image.asset(
                          'assets/img/logo_segura.png',
                          height: 44 * scale,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 6 * scale),
                        Text(
                          'Cuerpo de Agentes de Control Municipal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF1D3F73),
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          'SIGO-GCAM',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF00A6D6),
                            fontSize: 10 * scale,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                          ),
                        ),
                        SizedBox(height: 18 * scale),
                        // Badge icon
                        BadgeIcon(
                          metaCartillas: metaCartillas,
                          size: 90 * scale,
                          unlocked: true,
                        ),
                        SizedBox(height: 12 * scale),
                        // User name
                        Text(
                          nombreUsuario,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF1F2937),
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        // Badge title
                        Text(
                          titulo,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF1D3F73),
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        // Level
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10 * scale,
                            vertical: 3 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            nivelName,
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 10 * scale),
                        // Cartillas message
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14 * scale,
                            vertical: 10 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC400).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10 * scale),
                            border: Border.all(
                              color: const Color(0xFFFFC400).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Por haber completado $totalCartillas cartillas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF1F2937),
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 14 * scale),
                        // Congratulations
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, color: const Color(0xFFFFC400), size: 18 * scale),
                            SizedBox(width: 6 * scale),
                            Text(
                              '¡Felicidades!',
                              style: TextStyle(
                                color: const Color(0xFF00A6D6),
                                fontSize: 20 * scale,
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
                            SizedBox(width: 6 * scale),
                            Icon(Icons.star, color: const Color(0xFFFFC400), size: 18 * scale),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Corner decorations
            Positioned(
              top: 10 * scale,
              left: 10 * scale,
              child: Icon(Icons.star,
                color: const Color(0xFFFFC400).withValues(alpha: 0.4),
                size: 24 * scale,
              ),
            ),
            Positioned(
              top: 14 * scale,
              right: 16 * scale,
              child: Icon(Icons.star,
                color: Colors.white.withValues(alpha: 0.3),
                size: 18 * scale,
              ),
            ),
            Positioned(
              bottom: 12 * scale,
              left: 18 * scale,
              child: Icon(Icons.star,
                color: Colors.white.withValues(alpha: 0.25),
                size: 20 * scale,
              ),
            ),
            Positioned(
              bottom: 8 * scale,
              right: 12 * scale,
              child: Icon(Icons.star,
                color: const Color(0xFFFFC400).withValues(alpha: 0.35),
                size: 28 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// CONFETTI PAINTER
// ──────────────────────────────────────────────

class _CardConfettiPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  _CardConfettiPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final colors = [
      const Color(0xFFFFC400),
      Colors.white.withValues(alpha: 0.6),
      const Color(0xFFFFD700),
      accentColor.withValues(alpha: 0.5),
      primaryColor.withValues(alpha: 0.3),
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
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: s, height: s * 0.6),
          Paint()..color = color,
        );
      } else {
        final a = rng.nextDouble() * math.pi;
        canvas.drawLine(
          Offset(x - s * math.cos(a), y - s * math.sin(a)),
          Offset(x + s * math.cos(a), y + s * math.sin(a)),
          Paint()
            ..color = color
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CardConfettiPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.accentColor != accentColor;
}

// ──────────────────────────────────────────────
// ACTION ROW
// ──────────────────────────────────────────────

class _ActionRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? widget.color.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: _hovered
                ? (Matrix4.identity()..setTranslationRaw(4, 0, 0))
                : Matrix4.identity(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: _hovered ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, size: 20, color: widget.color),
                ),
                const SizedBox(width: 14),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AdmTokens.grey800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
