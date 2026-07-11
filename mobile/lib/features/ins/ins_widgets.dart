import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../adm/adm_design_tokens.dart';
import 'ins_achievement_theme.dart';
import 'ins_badge_dlg.dart';
import 'ins_icn_wdg.dart';
import 'ins_mdl.dart';

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
      if (!badges[i].desbloqueada) {
        return i;
      }
    }
    return badges.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final badges = widget.allBadges;
    if (badges.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < badges.length; i++) ...[
              if (i > 0) _TimelineConnector(
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

  const _TimelineConnector({
    required this.unlocked,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? AdmTokens.primary : AdmTokens.grey200;
    return SizedBox(
      width: 40,
      child: Center(
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
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
    _breathAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _breathingCtrl, curve: Curves.easeInOut),
    );
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

  @override
  Widget build(BuildContext context) {
    final rank = AchievementTheme.forCartillas(widget.badge.metaCartillas);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _hovered ? (Matrix4.identity()..setTranslationRaw(0, -3, 0)) : Matrix4.identity(),
        width: 110,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 72,
              child: Center(
                child: widget.isCurrent
                    ? AnimatedBuilder(
                        animation: _breathAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _breathAnim.value,
                          child: child,
                        ),
                        child: _NodeIcon(
                          badge: widget.badge,
                          isUnlocked: widget.isUnlocked,
                          isCurrent: widget.isCurrent,
                          rank: rank,
                        ),
                      )
                    : _NodeIcon(
                        badge: widget.badge,
                        isUnlocked: widget.isUnlocked,
                        isCurrent: widget.isCurrent,
                        rank: rank,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.badge.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: widget.isUnlocked || widget.isCurrent ? FontWeight.w600 : FontWeight.w400,
                color: widget.isUnlocked || widget.isCurrent ? AdmTokens.grey800 : AdmTokens.grey400,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.badge.metaCartillas} cart.',
              style: TextStyle(
                fontSize: 10,
                color: widget.isUnlocked || widget.isCurrent ? AdmTokens.grey500 : AdmTokens.grey300,
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
  final AchievementTheme rank;

  const _NodeIcon({
    required this.badge,
    required this.isUnlocked,
    required this.isCurrent,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (isUnlocked)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AdmTokens.action.withValues(alpha: 0.12),
            ),
          ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUnlocked
                ? AdmTokens.primary
                : isCurrent
                    ? AdmTokens.secondary
                    : AdmTokens.grey100,
            border: Border.all(
              color: isUnlocked
                  ? AdmTokens.action
                  : isCurrent
                      ? AdmTokens.secondary
                      : AdmTokens.grey200,
              width: isUnlocked ? 2.5 : 2,
            ),
          ),
          child: ClipOval(
            child: BadgeIcon(
              metaCartillas: badge.metaCartillas,
              size: 30,
              unlocked: isUnlocked || isCurrent,
            ),
          ),
        ),
        if (isUnlocked)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AdmTokens.success,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.check_rounded, size: 11, color: Colors.white),
            ),
          ),
        if (!isUnlocked && !isCurrent)
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(Icons.lock_rounded, size: 14, color: AdmTokens.grey300),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// PROGRESS CARD — circular + share button
// ──────────────────────────────────────────────

class AchievementProgressCard extends StatelessWidget {
  final InsProgresoMdl progreso;
  final VoidCallback onShare;
  final String nombreUsuario;

  const AchievementProgressCard({
    super.key,
    required this.progreso,
    required this.onShare,
    required this.nombreUsuario,
  });

  @override
  Widget build(BuildContext context) {
    final complete = progreso.proximaInsignia == null;
    final pct = progreso.porcentajeProgreso.clamp(0, 100) / 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdmTokens.surface,
        borderRadius: BorderRadius.circular(AdmTokens.radiusMd),
        boxShadow: AdmTokens.cardShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: pct,
                color: complete ? AdmTokens.success : AdmTokens.primary,
                trackColor: AdmTokens.grey100,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(pct * 100).toInt()}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AdmTokens.grey900,
                      ),
                    ),
                    Text(
                      '%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdmTokens.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complete
                      ? 'Todas las insignias desbloqueadas'
                      : progreso.proximaInsignia!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AdmTokens.grey900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  complete
                      ? '${progreso.totalCartillasGeneradas} cartillas generadas.'
                      : '${progreso.totalCartillasGeneradas}/${progreso.metaProxima} cartillas.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AdmTokens.grey500,
                  ),
                ),
                if (!complete) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Faltan ${progreso.cartillasFaltantes} cartillas para desbloquear esta insignia.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AdmTokens.grey400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          _ShareButton(
            onTap: onShare,
            label: 'Compartir progreso',
            icon: Icons.share_outlined,
            compact: false,
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

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
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
      old.progress != progress || old.color != color;
}

// ──────────────────────────────────────────────
// SHARE BUTTON
// ──────────────────────────────────────────────

class _ShareButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final bool compact;
  final bool enabled;

  const _ShareButton({
    required this.onTap,
    required this.label,
    required this.icon,
    this.compact = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AdmTokens.primary : AdmTokens.grey100,
      borderRadius: BorderRadius.circular(10),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 20,
            vertical: compact ? 10 : 14,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 16 : 18,
                color: enabled ? Colors.white : AdmTokens.grey400),
              if (!compact) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.white : AdmTokens.grey400,
                    )),
                    Text(
                      'Comparte tu avance en redes sociales.',
                      style: TextStyle(
                        fontSize: 10,
                        color: enabled
                            ? Colors.white.withValues(alpha: 0.7)
                            : AdmTokens.grey300,
                      ),
                    ),
                  ],
                ),
              ],
            ],
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
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AdmTokens.surface,
          borderRadius: BorderRadius.circular(AdmTokens.radiusMd),
          boxShadow: AdmTokens.cardShadow,
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.leaderboard_outlined, size: 40, color: AdmTokens.grey300),
              const SizedBox(height: 12),
              Text('Próximamente', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: AdmTokens.grey500,
              )),
              const SizedBox(height: 4),
              Text('El ranking de usuarios estará disponible pronto.', style: TextStyle(
                fontSize: 13, color: AdmTokens.grey400,
              )),
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
            child: Text('Top Usuarios', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: AdmTokens.grey900,
            )),
          ),
          DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 56,
            horizontalMargin: 20,
            columnSpacing: 16,
            showCheckboxColumn: false,
            headingRowColor: WidgetStateProperty.all(AdmTokens.grey50),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) return AdmTokens.primary.withValues(alpha: 0.04);
              return null;
            }),
            border: TableBorder(
              horizontalInside: BorderSide(color: AdmTokens.grey100, width: 0.5),
            ),
            columns: const [
              DataColumn(label: Text('#', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdmTokens.grey500))),
              DataColumn(label: Text('Usuario', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdmTokens.grey500))),
              DataColumn(label: Text('Insignia más alta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdmTokens.grey500))),
              DataColumn(label: Text('Nivel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdmTokens.grey500))),
              DataColumn(label: Text('Progreso', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdmTokens.grey500))),
            ],
            rows: List.generate(users.length.clamp(0, 10), (i) {
              final u = users[i];
              return DataRow(cells: [
                DataCell(Text('${i + 1}', style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AdmTokens.grey700,
                ))),
                DataCell(Text(u.nombre, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: AdmTokens.grey800,
                ))),
                DataCell(Text(u.badgeName, style: const TextStyle(
                  fontSize: 12, color: AdmTokens.grey600,
                ))),
                DataCell(_LevelBadge(label: u.level)),
                DataCell(SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    value: u.progress.clamp(0, 1),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                    backgroundColor: AdmTokens.grey100,
                    valueColor: AlwaysStoppedAnimation<Color>(_levelColor(u.level)),
                  ),
                )),
              ]);
            }),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              'Ver ranking completo →',
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
      case 'leyenda': return const Color(0xFFF1C40F);
      case 'comandante': return const Color(0xFFBDC3C7);
      case 'élite': case 'elite': return const Color(0xFF8E44AD);
      case 'profesional': return const Color(0xFFE67E22);
      case 'experimentado': return const Color(0xFF1ABC9C);
      case 'operativo': return const Color(0xFF2ECC71);
      default: return AdmTokens.primary;
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
        color: _levelColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _levelColor,
      )),
    );
  }

  Color get _levelColor {
    switch (label.toLowerCase()) {
      case 'leyenda': return const Color(0xFFF1C40F);
      case 'comandante': return const Color(0xFF7F8C8D);
      case 'élite': case 'elite': return const Color(0xFF8E44AD);
      case 'profesional': return const Color(0xFFE67E22);
      case 'experimentado': return const Color(0xFF1ABC9C);
      case 'operativo': return const Color(0xFF2ECC71);
      default: return AdmTokens.primary;
    }
  }
}

class UserRankData {
  final String nombre;
  final String badgeName;
  final String level;
  final double progress;
  final int totalCartillas;
  final String initials;

  UserRankData({
    required this.nombre,
    required this.badgeName,
    required this.level,
    required this.progress,
    required this.totalCartillas,
    required this.initials,
  });
}

// ──────────────────────────────────────────────
// TOP USERS CARDS (top 3)
// ──────────────────────────────────────────────

class TopUsersCards extends StatelessWidget {
  final List<UserRankData> users;

  const TopUsersCards({super.key, required this.users});

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AdmTokens.surface,
          borderRadius: BorderRadius.circular(AdmTokens.radiusMd),
          boxShadow: AdmTokens.cardShadow,
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.emoji_events_outlined, size: 40, color: AdmTokens.grey300),
              const SizedBox(height: 12),
              Text('Mejores usuarios', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: AdmTokens.grey500,
              )),
              const SizedBox(height: 4),
              Text('Los mejores agentes aparecerán aquí.', style: TextStyle(
                fontSize: 13, color: AdmTokens.grey400,
              )),
            ],
          ),
        ),
      );
    }

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
          const Text('Mejores Usuarios', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: AdmTokens.grey900,
          )),
          const SizedBox(height: 16),
          for (int i = 0; i < users.length.clamp(0, 3); i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _TopUserCard(rank: i, user: users[i]),
          ],
        ],
      ),
    );
  }
}

class _TopUserCard extends StatelessWidget {
  final int rank;
  final UserRankData user;

  const _TopUserCard({required this.rank, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdmTokens.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdmTokens.grey100),
      ),
      child: Row(
        children: [
          Text(TopUsersCards._medals[rank], style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 22,
            backgroundColor: AdmTokens.primary,
            child: Text(
              user.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.nombre, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AdmTokens.grey900,
                )),
                const SizedBox(height: 2),
                Text(user.badgeName, style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: AdmTokens.grey600,
                )),
                const SizedBox(height: 1),
                Text('${user.totalCartillas} cartillas', style: const TextStyle(
                  fontSize: 11, color: AdmTokens.grey400,
                )),
              ],
            ),
          ),
          _LevelBadge(label: user.level),
        ],
      ),
    );
  }
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
    final locked = badges.where((b) => !b.desbloqueada && !_isInProgress(b)).toList();

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
                  fontSize: 13, fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(child: _TabLabel('Desbloqueadas', unlocked.length, AdmTokens.success)),
                  Tab(child: _TabLabel('En progreso', inProgress.length, AdmTokens.primary)),
                  Tab(child: _TabLabel('Bloqueadas', locked.length, AdmTokens.grey400)),
                ],
              ),
              SizedBox(
                height: 360,
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _BadgeGrid(badges: unlocked, totalCartillas: widget.totalCartillas, nombreUsuario: widget.nombreUsuario, type: _BadgeType.unlocked),
                    _BadgeGrid(badges: inProgress, totalCartillas: widget.totalCartillas, nombreUsuario: widget.nombreUsuario, type: _BadgeType.inProgress),
                    _BadgeGrid(badges: locked, totalCartillas: widget.totalCartillas, nombreUsuario: widget.nombreUsuario, type: _BadgeType.locked),
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
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, size: 36, color: AdmTokens.grey300),
              const SizedBox(height: 12),
              Text(
                type == _BadgeType.unlocked
                    ? 'Aún no has desbloqueado insignias.'
                    : type == _BadgeType.inProgress
                        ? 'No hay insignias en progreso.'
                        : 'No hay insignias bloqueadas.',
                style: TextStyle(fontSize: 13, color: AdmTokens.grey400),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 700 ? 3 : constraints.maxWidth >= 500 ? 2 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 220,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdmTokens.surface,
        borderRadius: BorderRadius.circular(AdmTokens.radiusMd),
        border: Border.all(
          color: isUnlocked
              ? AdmTokens.action.withValues(alpha: 0.5)
              : AdmTokens.grey100,
        ),
        boxShadow: isUnlocked ? [
          BoxShadow(
            color: AdmTokens.action.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BadgeIcon(
                metaCartillas: badge.metaCartillas,
                size: 40,
                unlocked: isUnlocked || isInProgress,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isUnlocked ? AdmTokens.grey900 : AdmTokens.grey500,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AdmTokens.grey500,
            ),
          ),
          const SizedBox(height: 8),
          if (isInProgress)
            Column(
              children: [
                LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: AdmTokens.grey100,
                  valueColor: const AlwaysStoppedAnimation<Color>(AdmTokens.primary),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$totalCartillas/${badge.metaCartillas}',
                    style: const TextStyle(fontSize: 10, color: AdmTokens.grey400),
                  ),
                ),
              ],
            )
          else if (isUnlocked)
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 14, color: AdmTokens.success),
                const SizedBox(width: 4),
                Text(
                  'Desbloqueada con ${badge.totalAlDesbloquear ?? badge.metaCartillas} cartillas',
                  style: const TextStyle(fontSize: 10, color: AdmTokens.grey400),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(Icons.lock_rounded, size: 14, color: AdmTokens.grey300),
                const SizedBox(width: 4),
                Text(
                  'Bloqueada hasta alcanzar la meta',
                  style: const TextStyle(fontSize: 10, color: AdmTokens.grey300),
                ),
              ],
            ),
          const SizedBox(height: 10),
          _ShareButton(
            onTap: () => _share(context),
            label: isUnlocked ? 'Compartir logro' : isInProgress ? 'Compartir progreso' : 'Compartir',
            icon: Icons.share_outlined,
            compact: true,
            enabled: isUnlocked || isInProgress,
          ),
        ],
      ),
    );
  }

  void _share(BuildContext context) {
    final meta = badge.metaCartillas;
    final total = badge.totalAlDesbloquear ?? meta;
    showDialog(
      context: context,
      builder: (_) => AchievementUnlockedDialog(
        insignia: InsigniaDesbloqueadaMdl(
          titulo: badge.titulo,
          mensaje: badge.descripcion,
          icono: meta.toString(),
        ),
        totalCartillas: total,
        nombreUsuario: nombreUsuario,
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// HELPER: build user rank data from current user
// ──────────────────────────────────────────────

class UserRankBuilder {
  static UserRankData fromCurrentUser({
    required String nombre,
    required List<InsMdl> allBadges,
    required int totalCartillas,
  }) {
    final unlocked = allBadges.where((b) => b.desbloqueada).toList();
    final highest = unlocked.isEmpty
        ? allBadges.isNotEmpty
            ? allBadges.first
            : null
        : unlocked.last;

    final level = highest != null
        ? AchievementTheme.forCartillas(highest.metaCartillas).nombre
        : 'Novato';

    final initials = nombre.isNotEmpty
        ? nombre.split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join()
        : '??';

    final nextBadge = allBadges.isNotEmpty
        ? allBadges.lastWhere(
            (b) => !b.desbloqueada,
            orElse: () => allBadges.last,
          )
        : null;

    final progress = nextBadge != null
        ? (totalCartillas / nextBadge.metaCartillas).clamp(0.0, 1.0).toDouble()
        : 1.0;

    return UserRankData(
      nombre: nombre,
      badgeName: highest?.titulo ?? 'Sin insignias',
      level: level,
      progress: progress,
      totalCartillas: totalCartillas,
      initials: initials,
    );
  }
}
