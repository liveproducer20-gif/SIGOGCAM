import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../adm/adm_design_tokens.dart';
import 'badge_catalog.dart';
import 'ins_achievement_theme.dart';
import 'ins_icn_wdg.dart';
import 'ins_mdl.dart';
import 'ins_share_modal.dart';

// ──────────────────────────────────────────────
// TIMELINE — horizontal progress stepper
// ──────────────────────────────────────────────

class AchievementsTimeline extends StatefulWidget {
  final List<InsMdl> allBadges;
  final InsProgresoMdl progreso;

  const AchievementsTimeline({
    super.key,
    required this.allBadges,
    required this.progreso,
  });

  @override
  State<AchievementsTimeline> createState() => _AchievementsTimelineState();
}

class _AchievementsTimelineState extends State<AchievementsTimeline>
    with SingleTickerProviderStateMixin {
  int? _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _findCurrentIndex();
  }

  int _findCurrentIndex() {
    final badges = widget.allBadges;
    if (badges.isEmpty) return 0;
    for (int i = 0; i < badges.length; i++) {
      if (!badges[i].desbloqueada) return i;
    }
    return badges.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final badges = widget.allBadges;
    if (badges.isEmpty) return const SizedBox.shrink();

    final unlockedCount = badges.where((b) => b.desbloqueada).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 660;
        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTimeline(badges)),
              const SizedBox(width: 12),
              _GeneralProgressIndicator(
                unlocked: unlockedCount,
                total: badges.length,
              ),
            ],
          );
        }
        return Column(
          children: [
            _buildTimeline(badges),
            const SizedBox(height: 12),
            _GeneralProgressIndicator(
              unlocked: unlockedCount,
              total: badges.length,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeline(List<InsMdl> badges) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < badges.length; i++) ...[
              if (i > 0)
                _TimelineConnector(
                  unlocked: badges[i - 1].desbloqueada,
                  isCurrent: i == _currentIndex,
                ),
              _TimelineNode(
                badge: badges[i],
                index: i,
                isCurrent: i == _currentIndex,
                isUnlocked: badges[i].desbloqueada,
                totalCartillas: widget.progreso.totalCartillasGeneradas,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  final bool unlocked;
  final bool isCurrent;

  const _TimelineConnector({required this.unlocked, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? AdmTokens.primary : AdmTokens.grey200;
    return SizedBox(
      width: 40,
      child: Center(
        child: Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _TimelineNode extends StatefulWidget {
  final InsMdl badge;
  final int index;
  final bool isCurrent;
  final bool isUnlocked;
  final int totalCartillas;

  const _TimelineNode({
    required this.badge,
    required this.index,
    required this.isCurrent,
    required this.isUnlocked,
    required this.totalCartillas,
  });

  @override
  State<_TimelineNode> createState() => _TimelineNodeState();
}

class _TimelineNodeState extends State<_TimelineNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingCtrl;
  late Animation<double> _breathAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _breathingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _breathAnim = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _breathingCtrl, curve: Curves.easeInOut));
    if (widget.isCurrent) {
      _breathingCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_TimelineNode old) {
    super.didUpdateWidget(old);
    if (widget.isCurrent && !old.isCurrent) {
      _breathingCtrl.repeat(reverse: true);
    } else if (!widget.isCurrent && old.isCurrent) {
      _breathingCtrl.stop();
      _breathingCtrl.reset();
    }
  }

  @override
  void dispose() {
    _breathingCtrl.dispose();
    super.dispose();
  }

  LevelTheme get _theme => widget.badge.levelTheme;

  @override
  Widget build(BuildContext context) {
    final node = gestureWidget();

    if (widget.isCurrent) {
      return AnimatedBuilder(
        animation: _breathAnim,
        builder: (_, child) =>
            Transform.scale(scale: _breathAnim.value, child: child),
        child: node,
      );
    }
    return node;
  }

  Widget gestureWidget() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _hovered
            ? (Matrix4.identity()..setTranslationRaw(0, -3, 0))
            : Matrix4.identity(),
        width: 110,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 92,
              child: Center(
                child: _NodeIcon(
                  badge: widget.badge,
                  isUnlocked: widget.isUnlocked,
                  isCurrent: widget.isCurrent,
                  theme: _theme,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Tooltip(
              message: widget.badge.titulo,
              child: Text(
                widget.badge.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: widget.isUnlocked || widget.isCurrent
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: widget.isUnlocked || widget.isCurrent
                      ? AdmTokens.grey800
                      : AdmTokens.grey400,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.badge.metaCartillas} cart.',
              style: TextStyle(
                fontSize: 10,
                color: widget.isUnlocked || widget.isCurrent
                    ? AdmTokens.grey500
                    : AdmTokens.grey300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeIcon extends StatelessWidget {
  final InsMdl badge;
  final bool isUnlocked;
  final bool isCurrent;
  final LevelTheme theme;

  const _NodeIcon({
    required this.badge,
    required this.isUnlocked,
    required this.isCurrent,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (isUnlocked) return _buildUnlocked();
    if (isCurrent) return _buildCurrent();
    return _buildLocked();
  }

  Widget _buildUnlocked() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AdmTokens.action.withValues(alpha: 0.12),
            boxShadow: [
              BoxShadow(
                color: AdmTokens.action.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AdmTokens.surface,
            border: Border.all(color: AdmTokens.action, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AdmTokens.action.withValues(alpha: 0.15),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipOval(
            child: BadgeIcon(
              metaCartillas: badge.metaCartillas,
              size: 46,
              unlocked: true,
            ),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AdmTokens.success,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AdmTokens.success.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrent() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AdmTokens.primary.withValues(alpha: 0.06),
            boxShadow: [
              BoxShadow(
                color: AdmTokens.primary.withValues(alpha: 0.18),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AdmTokens.surface,
            border: Border.all(color: AdmTokens.primary, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AdmTokens.primary.withValues(alpha: 0.1),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipOval(
            child: BadgeIcon(
              metaCartillas: badge.metaCartillas,
              size: 46,
              unlocked: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocked() {
    return Opacity(
      opacity: 0.6,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AdmTokens.grey100,
              border: Border.all(color: AdmTokens.grey200, width: 2),
            ),
            child: ClipOval(
              child: BadgeIcon(
                metaCartillas: badge.metaCartillas,
                size: 46,
                unlocked: false,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Icon(Icons.lock_rounded, size: 16, color: AdmTokens.grey400),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// GENERAL PROGRESS INDICATOR
// ──────────────────────────────────────────────

class _GeneralProgressIndicator extends StatelessWidget {
  final int unlocked;
  final int total;

  const _GeneralProgressIndicator({
    required this.unlocked,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (unlocked / total * 100).toInt() : 0;
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AdmTokens.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AdmTokens.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: progress,
                color: AdmTokens.primary,
                trackColor: AdmTokens.grey100,
                strokeWidth: 4,
              ),
              child: Center(
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AdmTokens.grey800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Progreso general',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AdmTokens.grey500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$unlocked / $total insignias',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AdmTokens.grey900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// PROGRESS SUMMARY CARDS
// ──────────────────────────────────────────────

class ProgressSummaryCards extends StatelessWidget {
  final int desbloqueadas;
  final int pendientes;
  final int cartillasRestantes;
  final String nivelActual;

  const ProgressSummaryCards({
    super.key,
    required this.desbloqueadas,
    required this.pendientes,
    required this.cartillasRestantes,
    required this.nivelActual,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 600 ? 4 : 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: _cardWidth(constraints.maxWidth, cols),
              child: _SummaryCard(
                icon: Icons.emoji_events_rounded,
                iconColor: AdmTokens.action,
                value: desbloqueadas.toString(),
                label: 'Desbloqueadas',
              ),
            ),
            SizedBox(
              width: _cardWidth(constraints.maxWidth, cols),
              child: _SummaryCard(
                icon: Icons.lock_rounded,
                iconColor: AdmTokens.grey400,
                value: pendientes.toString(),
                label: 'Pendientes',
              ),
            ),
            SizedBox(
              width: _cardWidth(constraints.maxWidth, cols),
              child: _SummaryCard(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFE67E22),
                value: cartillasRestantes.toString(),
                label: 'Cartillas restantes',
              ),
            ),
            SizedBox(
              width: _cardWidth(constraints.maxWidth, cols),
              child: _SummaryCard(
                icon: Icons.star_rounded,
                iconColor: AdmTokens.action,
                value: nivelActual,
                label: 'Nivel actual',
              ),
            ),
          ],
        );
      },
    );
  }

  double _cardWidth(double totalWidth, int cols) {
    if (cols == 4) return (totalWidth - 30) / 4;
    return (totalWidth - 10) / 2;
  }
}

class _SummaryCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _hovered
            ? (Matrix4.identity()..setTranslationRaw(0, -2, 0))
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _hovered ? AdmTokens.surface : AdmTokens.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? widget.iconColor.withValues(alpha: 0.3)
                : AdmTokens.grey100,
          ),
          boxShadow: _hovered ? AdmTokens.hoverShadow : AdmTokens.cardShadow,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.iconColor.withValues(
                  alpha: _hovered ? 0.15 : 0.1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, size: 18, color: widget.iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AdmTokens.grey900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AdmTokens.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// PROGRESS CARD — circular + details + share
// ──────────────────────────────────────────────

class AchievementProgressCard extends StatelessWidget {
  final InsProgresoMdl progreso;
  final VoidCallback onShare;
  final String nombreUsuario;
  final String nombreNivel;

  const AchievementProgressCard({
    super.key,
    required this.progreso,
    required this.onShare,
    required this.nombreUsuario,
    this.nombreNivel = 'Novato',
  });

  @override
  Widget build(BuildContext context) {
    final complete = progreso.proximaInsignia == null;
    final pct = progreso.porcentajeProgreso.clamp(0, 100) / 100;
    final theme = progreso.metaProxima != null
        ? LevelTheme.forMeta(progreso.metaProxima!)
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdmTokens.surface,
        borderRadius: BorderRadius.circular(AdmTokens.radiusMd),
        boxShadow: AdmTokens.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: pct,
                color: complete ? AdmTokens.success : AdmTokens.primary,
                trackColor: AdmTokens.grey100,
                strokeWidth: 7,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(pct * 100).toInt()}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AdmTokens.grey900,
                      ),
                    ),
                    Text(
                      '%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme?.accentColor ?? AdmTokens.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  complete
                      ? 'Todas las insignias desbloqueadas'
                      : progreso.proximaInsignia!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme?.titleColor ?? AdmTokens.grey900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  complete
                      ? '${progreso.totalCartillasGeneradas} cartillas generadas.'
                      : '${progreso.totalCartillasGeneradas} / ${progreso.metaProxima} cartillas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme?.subtitleColor ?? AdmTokens.grey500,
                  ),
                ),
                if (!complete) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5,
                      backgroundColor: AdmTokens.grey100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme?.progressColor ?? AdmTokens.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Faltan ${progreso.cartillasFaltantes} cartillas',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AdmTokens.grey400,
                        ),
                      ),
                      const Spacer(),
                      if (progreso.ultimaInsignia != null)
                        Text(
                          'Última: ${progreso.ultimaInsignia}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AdmTokens.grey400,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          ShareButton(
            onTap: onShare,
            label: 'Compartir progreso',
            subtitle: 'Comparte tu avance en redes sociales.',
            icon: Icons.share_outlined,
          ),
        ],
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = trackColor;
    canvas.drawCircle(center, radius, paint);

    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

// ──────────────────────────────────────────────
// SHARE BUTTON
// ──────────────────────────────────────────────

class ShareButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final String? subtitle;
  final IconData icon;
  final bool enabled;

  const ShareButton({
    super.key,
    required this.onTap,
    required this.label,
    this.subtitle,
    required this.icon,
    this.enabled = true,
  });

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Material(
        color: enabled
            ? (_hovered ? AdmTokens.secondary : AdmTokens.primary)
            : AdmTokens.grey100,
        borderRadius: BorderRadius.circular(10),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? widget.onTap : null,
          splashColor: Colors.white.withValues(alpha: 0.15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: enabled ? Colors.white : AdmTokens.grey400,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: enabled ? Colors.white : AdmTokens.grey400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: 10,
                          color: enabled
                              ? Colors.white.withValues(alpha: 0.7)
                              : AdmTokens.grey300,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// TOP USERS LEADERBOARD
// ──────────────────────────────────────────────

class TopUsersLeaderboard extends StatelessWidget {
  final List<UserRankData> users;

  const TopUsersLeaderboard({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AdmTokens.surface,
          borderRadius: BorderRadius.circular(AdmTokens.radiusMd),
          boxShadow: AdmTokens.cardShadow,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.leaderboard_outlined,
                size: 36,
                color: AdmTokens.grey300,
              ),
              const SizedBox(height: 10),
              Text(
                'Sin datos de ranking',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AdmTokens.grey500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'No hay usuarios activos para mostrar en este momento.',
                style: TextStyle(fontSize: 12, color: AdmTokens.grey400),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AdmTokens.surface,
        borderRadius: BorderRadius.circular(AdmTokens.radiusMd),
        boxShadow: AdmTokens.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Top Usuarios',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AdmTokens.grey900,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 60,
              horizontalMargin: 16,
              columnSpacing: 14,
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.all(AdmTokens.grey50),
              dataRowColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.hovered)) {
                  return AdmTokens.primary.withValues(alpha: 0.04);
                }
                return null;
              }),
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: AdmTokens.grey100,
                  width: 0.5,
                ),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    '#',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdmTokens.grey500,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Usuario',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdmTokens.grey500,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Insignia más alta',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdmTokens.grey500,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Nivel',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdmTokens.grey500,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Progreso',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdmTokens.grey500,
                    ),
                  ),
                ),
              ],
              rows: List.generate(users.length.clamp(0, 10), (i) {
                final u = users[i];
                final levelColor = _levelColor(u.level);
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: i < 3 ? levelColor : AdmTokens.grey500,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AdmTokens.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              u.initials,
                              style: const TextStyle(
                                color: AdmTokens.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            u.nombre,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AdmTokens.grey800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BadgeIcon(
                            metaCartillas: u.badgeMetaCartillas,
                            size: 22,
                            unlocked: true,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              u.badgeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AdmTokens.grey600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(_LevelBadge(label: u.level)),
                    DataCell(
                      SizedBox(
                        width: 110,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: u.progress.clamp(0, 1),
                                minHeight: 5,
                                backgroundColor: AdmTokens.grey100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  levelColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(u.progress.clamp(0, 1) * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: levelColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Text(
              'Top 10 según cartillas generadas',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdmTokens.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'máximo':
      case 'maximo':
        return const Color(0xFFFFD700);
      case 'mítico':
      case 'mitico':
        return const Color(0xFF4A7CC9);
      case 'supremo':
        return const Color(0xFF95A5A6);
      case 'leyenda':
        return const Color(0xFFCD7F32);
      case 'élite':
      case 'elite':
        return const Color(0xFFE74C3C);
      case 'experto':
        return const Color(0xFFE67E22);
      case 'avanzado':
        return const Color(0xFF8E44AD);
      case 'profesional':
        return const Color(0xFF1ABC9C);
      case 'operativo':
        return const Color(0xFF2ECC71);
      default:
        return const Color(0xFFF6C343);
    }
  }
}

class _LevelBadge extends StatelessWidget {
  final String label;
  const _LevelBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }

  Color get _color {
    switch (label.toLowerCase()) {
      case 'máximo':
      case 'maximo':
        return const Color(0xFFFFD700);
      case 'mítico':
      case 'mitico':
        return const Color(0xFF4A7CC9);
      case 'supremo':
        return const Color(0xFF95A5A6);
      case 'leyenda':
        return const Color(0xFFCD7F32);
      case 'élite':
      case 'elite':
        return const Color(0xFFE74C3C);
      case 'experto':
        return const Color(0xFFE67E22);
      case 'avanzado':
        return const Color(0xFF8E44AD);
      case 'profesional':
        return const Color(0xFF1ABC9C);
      case 'operativo':
        return const Color(0xFF2ECC71);
      default:
        return AdmTokens.primary;
    }
  }
}

// ──────────────────────────────────────────────
// USER RANK DATA
// ──────────────────────────────────────────────

class UserRankData {
  final String nombre;
  final String badgeName;
  final int badgeMetaCartillas;
  final String level;
  final double progress;
  final int totalCartillas;
  final String initials;

  UserRankData({
    required this.nombre,
    required this.badgeName,
    required this.badgeMetaCartillas,
    required this.level,
    required this.progress,
    required this.totalCartillas,
    required this.initials,
  });
}

// ──────────────────────────────────────────────
// TOP USERS CARDS (podium)
// ──────────────────────────────────────────────

class TopUsersCards extends StatelessWidget {
  final List<UserRankData> users;

  const TopUsersCards({super.key, required this.users});

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AdmTokens.surface,
          borderRadius: BorderRadius.circular(AdmTokens.radiusMd),
          boxShadow: AdmTokens.cardShadow,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 36,
                color: AdmTokens.grey300,
              ),
              const SizedBox(height: 10),
              Text(
                'Mejores usuarios',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AdmTokens.grey500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Los mejores agentes aparecerán aquí.',
                style: TextStyle(fontSize: 12, color: AdmTokens.grey400),
              ),
            ],
          ),
        ),
      );
    }

    final top3 = users.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdmTokens.surface,
        borderRadius: BorderRadius.circular(AdmTokens.radiusMd),
        boxShadow: AdmTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mejores Usuarios',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AdmTokens.grey900,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < top3.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _TopUserCard(rank: i, user: top3[i]),
          ],
        ],
      ),
    );
  }
}

class _TopUserCard extends StatefulWidget {
  final int rank;
  final UserRankData user;

  const _TopUserCard({required this.rank, required this.user});

  @override
  State<_TopUserCard> createState() => _TopUserCardState();
}

class _TopUserCardState extends State<_TopUserCard> {
  bool _hovered = false;

  Color get _borderColor {
    switch (widget.user.level.toLowerCase()) {
      case 'máximo':
      case 'maximo':
        return const Color(0xFFFFD700);
      case 'mítico':
      case 'mitico':
        return const Color(0xFF4A7CC9);
      case 'supremo':
        return const Color(0xFF95A5A6);
      case 'leyenda':
        return const Color(0xFFCD7F32);
      case 'élite':
      case 'elite':
        return const Color(0xFFE74C3C);
      case 'experto':
        return const Color(0xFFE67E22);
      case 'avanzado':
        return const Color(0xFF8E44AD);
      case 'profesional':
        return const Color(0xFF1ABC9C);
      case 'operativo':
        return const Color(0xFF2ECC71);
      default:
        return const Color(0xFFF6C343);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _hovered
            ? (Matrix4.identity()..setTranslationRaw(0, -2, 0))
            : Matrix4.identity(),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AdmTokens.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? _borderColor.withValues(alpha: 0.5)
                : _borderColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: _borderColor.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  TopUsersCards._medals[widget.rank],
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AdmTokens.primary.withValues(alpha: 0.1),
                  child: Text(
                    u.initials,
                    style: const TextStyle(
                      color: AdmTokens.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              u.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AdmTokens.grey900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              u.badgeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _borderColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${u.totalCartillas} cartillas',
              style: const TextStyle(fontSize: 11, color: AdmTokens.grey400),
            ),
            const SizedBox(height: 6),
            _LevelBadge(label: u.level),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// HELPER: build user rank data from current user
// ──────────────────────────────────────────────

class UserRankBuilder {
  static UserRankData fromRankingRow(Map<String, dynamic> row) {
    final nombres = row['nombres']?.toString().trim() ?? '';
    final apellidos = row['apellidos']?.toString().trim() ?? '';
    final nombre = '$nombres $apellidos'.trim();
    final total =
        int.tryParse(row['total_cartillas_generadas']?.toString() ?? '') ?? 0;
    final badgeName = row['insignia_titulo']?.toString().trim();
    final previousMeta =
        int.tryParse(row['insignia_meta']?.toString() ?? '') ?? 0;
    final nextMeta = int.tryParse(row['proxima_meta']?.toString() ?? '');
    final category = row['insignia_categoria']?.toString().trim();
    final progress = nextMeta == null
        ? 1.0
        : ((total - previousMeta) / (nextMeta - previousMeta))
              .clamp(0.0, 1.0)
              .toDouble();

    return UserRankData(
      nombre: nombre.isEmpty ? 'Usuario SIGO-GCAM' : nombre,
      badgeName: badgeName?.isNotEmpty == true ? badgeName! : 'Sin insignias',
      badgeMetaCartillas: previousMeta,
      level: category?.isNotEmpty == true ? category! : 'Novato',
      progress: progress,
      totalCartillas: total,
      initials: _initials(nombre),
    );
  }

  static UserRankData fromCurrentUser({
    required String nombre,
    required List<InsMdl> allBadges,
    required int totalCartillas,
  }) {
    final unlockedMetas = allBadges
        .where((b) => b.desbloqueada)
        .map((b) => b.metaCartillas)
        .toList();
    final highest = BadgeCatalog.lastUnlocked(unlockedMetas);

    final level = highest != null
        ? LevelTheme.forNivel(highest.nivel).name
        : 'Novato';

    final initials = _initials(nombre);

    final progress = BadgeCatalog.intervalProgress(
      totalCartillas,
      unlockedMetas,
    );

    return UserRankData(
      nombre: nombre,
      badgeName: highest?.name ?? 'Sin insignias',
      badgeMetaCartillas: highest?.metaCartillas ?? 0,
      level: level,
      progress: progress,
      totalCartillas: totalCartillas,
      initials: initials,
    );
  }

  static String _initials(String nombre) => nombre.isNotEmpty
      ? nombre
            .split(' ')
            .where((word) => word.isNotEmpty)
            .take(2)
            .map((word) => word[0].toUpperCase())
            .join()
      : '??';
}

// ──────────────────────────────────────────────
// ACHIEVEMENT TABS
// ──────────────────────────────────────────────

class AchievementTabs extends StatefulWidget {
  final List<InsMdl> allBadges;
  final int totalCartillas;
  final String nombreUsuario;
  final VoidCallback? onShareBadge;

  const AchievementTabs({
    super.key,
    required this.allBadges,
    required this.totalCartillas,
    required this.nombreUsuario,
    this.onShareBadge,
  });

  @override
  State<AchievementTabs> createState() => _AchievementTabsState();
}

class _AchievementTabsState extends State<AchievementTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badges = widget.allBadges;
    final unlocked = badges.where((b) => b.desbloqueada).toList();
    final inProgress = _getInProgress(badges);
    final locked = badges
        .where((b) => !b.desbloqueada && !_isInProgress(b))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AdmTokens.surface,
            borderRadius: BorderRadius.circular(AdmTokens.radiusMd),
            boxShadow: AdmTokens.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              TabBar(
                controller: _tabCtrl,
                labelColor: AdmTokens.primary,
                unselectedLabelColor: AdmTokens.grey500,
                indicatorColor: AdmTokens.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(
                    child: _TabLabel(
                      'Desbloqueadas',
                      unlocked.length,
                      AdmTokens.success,
                    ),
                  ),
                  Tab(
                    child: _TabLabel(
                      'En progreso',
                      inProgress.length,
                      AdmTokens.primary,
                    ),
                  ),
                  Tab(
                    child: _TabLabel(
                      'Bloqueadas',
                      locked.length,
                      AdmTokens.grey400,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 300,
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _BadgeGrid(
                      badges: unlocked,
                      totalCartillas: widget.totalCartillas,
                      nombreUsuario: widget.nombreUsuario,
                      type: _BadgeType.unlocked,
                    ),
                    _BadgeGrid(
                      badges: inProgress,
                      totalCartillas: widget.totalCartillas,
                      nombreUsuario: widget.nombreUsuario,
                      type: _BadgeType.inProgress,
                    ),
                    _BadgeGrid(
                      badges: locked,
                      totalCartillas: widget.totalCartillas,
                      nombreUsuario: widget.nombreUsuario,
                      type: _BadgeType.locked,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isInProgress(InsMdl badge) {
    return !badge.desbloqueada && badge.metaCartillas <= widget.totalCartillas;
  }

  List<InsMdl> _getInProgress(List<InsMdl> badges) {
    final result = <InsMdl>[];
    for (final b in badges) {
      if (_isInProgress(b)) result.add(b);
    }
    return result;
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _TabLabel(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

enum _BadgeType { unlocked, inProgress, locked }

class _BadgeGrid extends StatelessWidget {
  final List<InsMdl> badges;
  final int totalCartillas;
  final String nombreUsuario;
  final _BadgeType type;

  const _BadgeGrid({
    required this.badges,
    required this.totalCartillas,
    required this.nombreUsuario,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, size: 32, color: AdmTokens.grey300),
              const SizedBox(height: 10),
              Text(
                type == _BadgeType.unlocked
                    ? 'Aún no has desbloqueado insignias.'
                    : type == _BadgeType.inProgress
                    ? 'No hay insignias en progreso.'
                    : 'No hay insignias bloqueadas.',
                style: TextStyle(fontSize: 12, color: AdmTokens.grey400),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 700
              ? 3
              : constraints.maxWidth >= 500
              ? 2
              : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 155,
            ),
            itemBuilder: (_, i) => _AchievementCard(
              badge: badges[i],
              totalCartillas: totalCartillas,
              nombreUsuario: nombreUsuario,
              type: type,
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// ACHIEVEMENT CARD
// ──────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final InsMdl badge;
  final int totalCartillas;
  final String nombreUsuario;
  final _BadgeType type;

  const _AchievementCard({
    required this.badge,
    required this.totalCartillas,
    required this.nombreUsuario,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = type == _BadgeType.unlocked;
    final isInProgress = type == _BadgeType.inProgress;
    final pct = isInProgress
        ? (totalCartillas / badge.metaCartillas).clamp(0.0, 1.0).toDouble()
        : isUnlocked
        ? 1.0
        : 0.0;

    final theme = badge.levelTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdmTokens.surface,
        borderRadius: BorderRadius.circular(AdmTokens.radiusMd),
        border: Border.all(
          color: isUnlocked
              ? theme.borderColor.withValues(alpha: 0.4)
              : isInProgress
              ? AdmTokens.primary.withValues(alpha: 0.3)
              : AdmTokens.grey100,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: theme.glowColor,
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BadgeIcon(
                metaCartillas: badge.metaCartillas,
                size: 34,
                unlocked: isUnlocked || isInProgress,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isUnlocked
                            ? AdmTokens.grey900
                            : AdmTokens.grey500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _StatusBadge(type: type),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Meta: ${badge.metaCartillas} cartillas',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? theme.subtitleColor : AdmTokens.grey400,
            ),
          ),
          const SizedBox(height: 6),
          if (isInProgress)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor: AdmTokens.grey100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.progressColor,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(pct * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: theme.progressColor,
                      ),
                    ),
                    Text(
                      '$totalCartillas/${badge.metaCartillas}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AdmTokens.grey400,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else if (isUnlocked)
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 13,
                  color: AdmTokens.success,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Desbloqueada con ${badge.totalAlDesbloquear ?? badge.metaCartillas} cartillas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AdmTokens.grey400,
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(Icons.lock_rounded, size: 13, color: AdmTokens.grey300),
                const SizedBox(width: 4),
                Text(
                  'Bloqueada hasta alcanzar la meta',
                  style: const TextStyle(fontSize: 9, color: AdmTokens.grey300),
                ),
              ],
            ),
          const SizedBox(height: 6),
          ShareButton(
            onTap: () => _share(context),
            label: isUnlocked
                ? 'Compartir logro'
                : isInProgress
                ? 'Compartir progreso'
                : 'Compartir',
            icon: Icons.share_outlined,
            enabled: isUnlocked || isInProgress,
          ),
        ],
      ),
    );
  }

  void _share(BuildContext context) {
    final meta = badge.metaCartillas;
    final total = badge.totalAlDesbloquear ?? meta;
    final catalogEntry = BadgeCatalog.byMeta(meta);
    showShareAchievement(
      context,
      titulo: badge.titulo,
      mensaje: badge.descripcion,
      metaCartillas: meta,
      totalCartillas: total,
      nombreUsuario: nombreUsuario,
      nivelName: catalogEntry != null
          ? LevelTheme.forNivel(catalogEntry.nivel).name
          : null,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _BadgeType type;

  const _StatusBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (type) {
      _BadgeType.unlocked => ('DESBLOQUEADA', AdmTokens.success),
      _BadgeType.inProgress => ('EN PROGRESO', AdmTokens.primary),
      _BadgeType.locked => ('BLOQUEADA', AdmTokens.grey400),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
