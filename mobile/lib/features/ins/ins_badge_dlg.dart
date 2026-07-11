import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

import 'ins_achievement_theme.dart';
import 'ins_icn_wdg.dart';
import 'ins_mdl.dart';

class AchievementUnlockedDialog extends StatefulWidget {
  final InsigniaDesbloqueadaMdl insignia;
  final int? totalCartillas;
  final String? nombreUsuario;
  final VoidCallback? onContinue;

  const AchievementUnlockedDialog({
    super.key,
    required this.insignia,
    this.totalCartillas,
    this.nombreUsuario,
    this.onContinue,
  });

  @override
  State<AchievementUnlockedDialog> createState() =>
      _AchievementUnlockedDialogState();
}

class _AchievementUnlockedDialogState extends State<AchievementUnlockedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _backdropFade;
  late final Animation<double> _dialogScale;
  late final Animation<double> _dialogFade;
  late final Animation<double> _badgeScale;
  late final Animation<double> _badgeRot1;
  late final Animation<double> _badgeRot2;
  late final Animation<double> _glowFade;
  late final Animation<double> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _contentFade;
  late final Animation<double> _progressAnim;

  AchievementTheme get _theme =>
      AchievementTheme.forCartillas(int.tryParse(widget.insignia.icono) ?? 0);

  int get _meta => int.tryParse(widget.insignia.icono) ?? 0;
  int get _total => widget.totalCartillas ?? _meta;
  double get _pct => _meta > 0 ? (_total / _meta).clamp(0, 1) : 0;

  final _repaintKey = GlobalKey();
  bool _generating = false;
  bool _pressedClose = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _backdropFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.15, curve: Curves.easeOut),
      ),
    );

    _dialogScale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.05, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _dialogFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.05, 0.35, curve: Curves.easeOut),
      ),
    );

    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.15), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.92), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1), weight: 10),
    ]).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.7, curve: Curves.easeOut),
    ));

    _badgeRot1 = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.15, 0.4, curve: Curves.easeOut),
      ),
    );

    _badgeRot2 = Tween<double>(begin: 0.1, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 0.7, curve: Curves.elasticOut),
      ),
    );

    _glowFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    _titleSlide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.35, 0.6, curve: Curves.easeOut),
      ),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.35, 0.6, curve: Curves.easeOut),
      ),
    );

    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.55, 0.8, curve: Curves.easeOut),
      ),
    );

    _progressAnim = Tween<double>(begin: 0, end: _pct).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.7, 1, curve: Curves.easeOutCubic),
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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => _buildStack(context),
    );
  }

  Widget _buildStack(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isDesktop = screenW >= 768;
    final cardW = isDesktop ? 600.0 : screenW * 0.92;
    final metaColor = _theme;

    return Stack(
      children: [
        // Backdrop with blur
        Positioned.fill(
          child: GestureDetector(
            onTap: _pressedClose ? null : _handleClose,
            child: AnimatedBuilder(
              animation: _backdropFade,
              builder: (context, _) {
                if (_backdropFade.value <= 0) return const SizedBox();
                return Opacity(
                  opacity: _backdropFade.value,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: 4 * _backdropFade.value,
                        sigmaY: 4 * _backdropFade.value,
                      ),
                      child: Container(color: Colors.black54),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Dialog card
        Center(
          child: AnimatedBuilder(
            animation: _dialogFade,
            builder: (context, _) {
              if (_dialogFade.value <= 0 && _dialogScale.value < 0.9) {
                return const SizedBox();
              }
              return Opacity(
                opacity: _dialogFade.value,
                child: Transform.scale(
                  scale: _dialogScale.value,
                  child: _buildCard(context, cardW, metaColor),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, double cardW, AchievementTheme thm) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: cardW,
        constraints: const BoxConstraints(maxHeight: 0.9),
        margin: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AchievementTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: thm.borderColor.withValues(alpha: 0.15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Particles overlay
            Positioned.fill(
              child: IgnorePointer(
                child: _buildParticles(thm),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(thm),
                  _buildBadgeSection(thm),
                  _buildTextSection(thm),
                  _buildDivider(thm),
                  _buildProgressSection(thm),
                  _buildDivider(thm),
                  _buildActions(context, thm),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Close button
            Positioned(
              top: 12,
              right: 12,
              child: _buildCloseButton(thm),
            ),
            // Hidden share card for capture
            Positioned(
              left: -9999,
              top: 0,
              child: RepaintBoundary(
                key: _repaintKey,
                child: _buildShareCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AchievementTheme thm) {
    return AnimatedBuilder(
      animation: _titleFade,
      builder: (context, _) {
        return Opacity(
          opacity: _titleFade.value,
          child: Transform.translate(
            offset: Offset(0, _titleSlide.value),
            child: Padding(
              padding: const EdgeInsets.only(left: 48, right: 48, top: 32),
              child: Column(
                children: [
                  Text(
                    'NUEVA INSIGNIA DESBLOQUEADA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: thm.subtitleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '¡Felicidades!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: thm.titleColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Has alcanzado un nuevo logro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: thm.subtitleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeSection(AchievementTheme thm) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final rot = _badgeRot1.value + _badgeRot2.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow
              if (_glowFade.value > 0)
                Opacity(
                  opacity: _glowFade.value * 0.6,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: thm.accentColor.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: thm.accentColor.withValues(alpha: 0.25),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              // Badge icon
              Transform.rotate(
                angle: rot,
                child: Transform.scale(
                  scale: _badgeScale.value,
                  child: BadgeIcon(
                    metaCartillas: _meta,
                    size: 90,
                    unlocked: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextSection(AchievementTheme thm) {
    return AnimatedBuilder(
      animation: _contentFade,
      builder: (context, _) {
        return Opacity(
          opacity: _contentFade.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  widget.insignia.titulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: thm.borderColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.insignia.mensaje,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: thm.subtitleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider(AchievementTheme thm) {
    return AnimatedBuilder(
      animation: _contentFade,
      builder: (context, _) {
        return Opacity(
          opacity: _contentFade.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Container(height: 1, color: thm.dividerColor),
          ),
        );
      },
    );
  }

  Widget _buildProgressSection(AchievementTheme thm) {
    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (context, _) {
        return Opacity(
          opacity: _contentFade.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progreso',
                  style: TextStyle(
                    color: thm.subtitleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$_total',
                      style: TextStyle(
                        color: thm.borderColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ' / $_meta cartillas',
                      style: TextStyle(
                        color: thm.subtitleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(_pct * 100).round()}%',
                      style: TextStyle(
                        color: thm.accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 10,
                    width: double.infinity,
                    color: thm.dividerColor,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnim.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: thm.progressColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, AchievementTheme thm) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    return AnimatedBuilder(
      animation: _contentFade,
      builder: (context, _) {
        return Opacity(
          opacity: _contentFade.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(
                        child: _buildShareButton(thm),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildContinueButton(thm),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: _buildShareButton(thm),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: _buildContinueButton(thm),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildShareButton(AchievementTheme thm) {
    if (_generating) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return _ActionBtn(
      label: 'Compartir',
      icon: Icons.share_outlined,
      bgColor: thm.buttonColor,
      textColor: thm.buttonTextColor,
      onPressed: _generating ? null : _share,
    );
  }

  Widget _buildContinueButton(AchievementTheme thm) {
    return _ActionBtn(
      label: 'Continuar',
      icon: Icons.arrow_forward_rounded,
      bgColor: AchievementTheme.white,
      textColor: thm.borderColor,
      borderColor: thm.dividerColor,
      onPressed: _handleClose,
    );
  }

  Widget _buildCloseButton(AchievementTheme thm) {
    return AnimatedBuilder(
      animation: _contentFade,
      builder: (context, _) {
        return Opacity(
          opacity: _contentFade.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _handleClose,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: thm.dividerColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7A8F)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticles(AchievementTheme thm) {
    return AnimatedBuilder(
      animation: _contentFade,
      builder: (context, _) {
        return Opacity(
          opacity: _contentFade.value * 0.5,
          child: CustomPaint(
            painter: _ParticlePainter(thm: thm),
          ),
        );
      },
    );
  }

  // ── Share logic ─────────────────────────────────────────────────

  Future<void> _share() async {
    setState(() => _generating = true);
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (_) {
          Future.microtask(() async {
            await _captureAndShare();
            if (mounted) Navigator.of(context, rootNavigator: true).pop();
          });
          return const SizedBox.shrink();
        },
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

  Future<void> _captureAndShare() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final boundary =
        _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('No se pudo capturar la imagen');

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('No se pudo generar la imagen');

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/insignia_${widget.insignia.titulo.replaceAll(' ', '_')}.png',
    );
    await file.writeAsBytes(byteData.buffer.asUint8List());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'He desbloqueado "${widget.insignia.titulo}" en SIGO-GCAM',
    );
  }

  Widget _buildShareCard() {
    final meta = _meta;
    final thm = _theme;
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(380, 560),
              painter: _ShareConfettiPainter(thm: thm),
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
                        AchievementTheme.white,
                        Color(0xFFFFF9E6),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/img/logo_segura.png',
                          height: 44,
                          fit: BoxFit.contain,
                        ),
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
                        if (widget.nombreUsuario != null)
                          Text(
                            widget.nombreUsuario!,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC400).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFFC400).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            widget.nombreUsuario != null
                                ? 'Por haber completado $meta cartillas.'
                                : widget.insignia.mensaje,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleClose() {
    if (_pressedClose) return;
    _pressedClose = true;
    widget.onContinue?.call();
    Navigator.of(context, rootNavigator: true).pop();
  }
}

// ── Action button widget ──────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback? onPressed;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          side: borderColor != null
              ? BorderSide(color: borderColor!)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}

// ── Confetti painter for share card ─────────────────────────────

class _ShareConfettiPainter extends CustomPainter {
  final AchievementTheme thm;

  _ShareConfettiPainter({required this.thm});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final colors = [
      thm.accentColor,
      AchievementTheme.white.withValues(alpha: 0.6),
      ...thm.confettiColors,
      thm.borderColor.withValues(alpha: 0.3),
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
  bool shouldRepaint(covariant _ShareConfettiPainter oldDelegate) =>
      oldDelegate.thm != thm;
}

// ── Particle painter for dialog background ──────────────────────

class _ParticlePainter extends CustomPainter {
  final AchievementTheme thm;

  _ParticlePainter({required this.thm});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(99);
    final colors = thm.particleColors;

    for (int i = 0; i < 15; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final s = 1.5 + rng.nextDouble() * 2.5;
      final color = colors[i % colors.length];
      canvas.drawCircle(Offset(x, y), s, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.thm != thm;
}

// ── Retro-compatible alias ───────────────────────────────────────

class BadgeUnlockDialog extends AchievementUnlockedDialog {
  const BadgeUnlockDialog({
    super.key,
    required super.insignia,
    super.totalCartillas,
    super.nombreUsuario,
    super.onContinue,
  });
}
