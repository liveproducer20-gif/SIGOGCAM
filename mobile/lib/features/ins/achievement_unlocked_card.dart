import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

import 'badge_catalog.dart';
import 'ins_achievement_theme.dart';
import 'ins_icn_wdg.dart';

enum AchievementCardMode { unlock, sharePreview }

Future<void> showAchievementCard(
  BuildContext context, {
  required String title,
  required int metaCartillas,
  required int totalCartillas,
  required String userName,
  AchievementCardMode mode = AchievementCardMode.unlock,
  VoidCallback? onContinue,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Logro desbloqueado',
    barrierColor: Colors.black.withValues(alpha: .72),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => AchievementUnlockedCard(
      title: title,
      metaCartillas: metaCartillas,
      totalCartillas: totalCartillas,
      userName: userName,
      mode: mode,
      onContinue: onContinue,
    ),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: .92, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: child,
      ),
    ),
  );
}

class AchievementUnlockedCard extends StatefulWidget {
  final String title;
  final int metaCartillas;
  final int totalCartillas;
  final String userName;
  final AchievementCardMode mode;
  final VoidCallback? onContinue;

  const AchievementUnlockedCard({
    super.key,
    required this.title,
    required this.metaCartillas,
    required this.totalCartillas,
    required this.userName,
    this.mode = AchievementCardMode.unlock,
    this.onContinue,
  });

  @override
  State<AchievementUnlockedCard> createState() =>
      _AchievementUnlockedCardState();
}

class _AchievementUnlockedCardState extends State<AchievementUnlockedCard>
    with SingleTickerProviderStateMixin {
  final _captureKey = GlobalKey();
  late final AnimationController _controller;
  late final Animation<double> _badgeScale;
  bool _busy = false;

  BadgeEntry? get _badge => BadgeCatalog.byMeta(widget.metaCartillas);
  LevelTheme get _theme => LevelTheme.forNivel(_badge?.nivel ?? 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: .72, end: 1.08), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1), weight: 45),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final previewWidth = math.min(520.0, size.width - 32).toDouble();
    final maxPreviewHeight = math.max(260.0, size.height - 235).toDouble();
    final artworkWidth = math.min(previewWidth, maxPreviewHeight).toDouble();

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: previewWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    key: _captureKey,
                    child: AchievementArtwork(
                      width: artworkWidth,
                      title: widget.title,
                      metaCartillas: widget.metaCartillas,
                      totalCartillas: widget.totalCartillas,
                      userName: widget.userName,
                      badgeScale: _badgeScale,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (_busy) {
      return const SizedBox(
        height: 52,
        child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    if (widget.mode == AchievementCardMode.unlock) {
      return Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Compartir',
              icon: Icons.share_outlined,
              color: _theme.buttonColor,
              foreground: _theme.buttonTextColor,
              onPressed: _share,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionButton(
              label: 'Continuar',
              icon: Icons.arrow_forward_rounded,
              color: Colors.white,
              foreground: const Color(0xFF17365F),
              onPressed: _close,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Compartir',
                icon: Icons.share_outlined,
                color: _theme.buttonColor,
                foreground: _theme.buttonTextColor,
                onPressed: _share,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: 'Descargar imagen',
                icon: Icons.download_outlined,
                color: const Color(0xFFE9EEF5),
                foreground: const Color(0xFF17365F),
                onPressed: _download,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _close,
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Cerrar'),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
        ),
      ],
    );
  }

  Future<File> _capture({Directory? directory}) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('No se pudo capturar el logro');
    final ratio = 1080 / boundary.size.width;
    final image = await boundary.toImage(pixelRatio: ratio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('No se pudo generar el PNG');
    final target = directory ?? await getTemporaryDirectory();
    final safeTitle = widget.title.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    final file = File('${target.path}/SIGO_GCAM_$safeTitle.png');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return file;
  }

  Future<void> _share() async {
    await _run(() async {
      final file = await _capture();
      await Share.shareXFiles([XFile(file.path)]);
    }, 'No fue posible compartir la imagen');
  }

  Future<void> _download() async {
    await _run(() async {
      final directory =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = await _capture(directory: directory);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imagen guardada en ${file.path}')),
      );
    }, 'No fue posible descargar la imagen');
  }

  Future<void> _run(Future<void> Function() action, String fallback) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$fallback: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _close() {
    widget.onContinue?.call();
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class AchievementArtwork extends StatelessWidget {
  final double width;
  final String title;
  final int metaCartillas;
  final int totalCartillas;
  final String userName;
  final Animation<double>? badgeScale;

  const AchievementArtwork({
    super.key,
    required this.width,
    required this.title,
    required this.metaCartillas,
    required this.totalCartillas,
    required this.userName,
    this.badgeScale,
  });

  @override
  Widget build(BuildContext context) {
    final badge = BadgeCatalog.byMeta(metaCartillas);
    final theme = LevelTheme.forNivel(badge?.nivel ?? 1);
    final level = badge?.nivel ?? 1;
    final scale = width / 1080;
    Widget scaledBadge = BadgeIcon(
      metaCartillas: metaCartillas,
      size: 300 * scale,
    );
    if (badgeScale != null) {
      scaledBadge = ScaleTransition(scale: badgeScale!, child: scaledBadge);
    }

    return Container(
      width: width,
      height: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38 * scale),
        border: Border.all(
          color: theme.accentColor.withValues(alpha: .8),
          width: 2 * scale,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF061B38), Color(0xFF001126), Color(0xFF020B18)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ArtworkPainter(theme))),
          Padding(
            padding: EdgeInsets.fromLTRB(
              72 * scale,
              48 * scale,
              72 * scale,
              48 * scale,
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/img/logo_sigo_gcam.png',
                  height: 105 * scale,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 30 * scale),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 34 * scale,
                    vertical: 13 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: theme.accentColor,
                      width: 2 * scale,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_open_rounded,
                        color: theme.accentColor,
                        size: 34 * scale,
                      ),
                      SizedBox(width: 16 * scale),
                      Text(
                        'LOGRO DESBLOQUEADO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28 * scale,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2 * scale,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24 * scale),
                scaledBadge,
                SizedBox(height: 20 * scale),
                Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 54 * scale,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8 * scale,
                  ),
                ),
                SizedBox(height: 18 * scale),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 30 * scale,
                    vertical: 13 * scale,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18 * scale),
                    border: Border.all(
                      color: theme.accentColor.withValues(alpha: .7),
                    ),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'NIVEL '),
                        TextSpan(
                          text: '$level',
                          style: TextStyle(color: theme.accentColor),
                        ),
                        TextSpan(
                          text: '   •   ${theme.name.toUpperCase()}',
                          style: const TextStyle(color: Color(0xFF42A5F5)),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25 * scale,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 26 * scale,
                    vertical: 20 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF071D3A).withValues(alpha: .82),
                    borderRadius: BorderRadius.circular(22 * scale),
                    border: Border.all(color: const Color(0xFF3C6B9E)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.person_rounded,
                          label: 'USUARIO',
                          value: userName,
                          scale: scale,
                        ),
                      ),
                      Container(
                        width: scale,
                        height: 70 * scale,
                        color: Colors.white38,
                      ),
                      Expanded(
                        child: _InfoItem(
                          icon: Icons.assignment_rounded,
                          label: 'CARTILLAS ALCANZADAS',
                          value: '$totalCartillas',
                          scale: scale,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30 * scale),
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.accentColor)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18 * scale),
                      child: Icon(
                        Icons.star_rounded,
                        color: theme.accentColor,
                        size: 32 * scale,
                      ),
                    ),
                    Expanded(child: Divider(color: theme.accentColor)),
                  ],
                ),
                SizedBox(height: 13 * scale),
                Text(
                  'LEALTAD  •  VALOR  •  ORDEN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20 * scale,
                    letterSpacing: 5 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double scale;
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.scale,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 60 * scale,
        height: 60 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0A2B57),
          border: Border.all(color: const Color(0xFF2196F3)),
        ),
        child: Icon(icon, color: Colors.white, size: 32 * scale),
      ),
      SizedBox(width: 15 * scale),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: const Color(0xFF42A5F5),
                fontSize: 15 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 23 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color foreground;
  final VoidCallback onPressed;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.foreground,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.label,
    child: MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.025 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: widget.onPressed,
            icon: Icon(widget.icon, size: 19),
            label: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: widget.foreground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ArtworkPainter extends CustomPainter {
  final LevelTheme theme;
  _ArtworkPainter(this.theme);
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              theme.glowColor.withValues(alpha: .55),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .28, size.height * .35),
              radius: size.width * .42,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * .28, size.height * .35),
      size.width * .42,
      glow,
    );
    final dot = Paint()..color = theme.accentColor.withValues(alpha: .42);
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 7; col++) {
        canvas.drawCircle(
          Offset(
            size.width * (.83 + col * .022),
            size.height * (.05 + row * .025),
          ),
          size.width * .003,
          dot,
        );
      }
    }
    final line = Paint()
      ..color = theme.accentColor.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .002;
    canvas.drawLine(Offset.zero, Offset(size.width * .17, 0), line);
    canvas.drawLine(Offset.zero, Offset(0, size.height * .17), line);
  }

  @override
  bool shouldRepaint(covariant _ArtworkPainter oldDelegate) =>
      oldDelegate.theme != theme;
}
