import 'package:flutter/material.dart';

class CartillaTypeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? description;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final double height;

  const CartillaTypeCard({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    required this.selected,
    this.enabled = true,
    required this.onTap,
    this.height = 152,
  });

  @override
  State<CartillaTypeCard> createState() => _CartillaTypeCardState();
}

class _CartillaTypeCardState extends State<CartillaTypeCard> {
  bool _isHovered = false;

  static const Color _darkBlue = Color(0xFF1D3F73);
  static const Color _selectedBg = Color(0xFFEAF0F8);
  static const Color _normalBorder = Color(0xFFD1D5DB);
  static const double _borderWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final hovered = _isHovered && !selected;

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.enabled ? widget.onTap : null,
            child: AnimatedContainer(
              width: double.infinity,
              height: widget.height,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? (selected ? _selectedBg : Colors.white)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? _darkBlue
                      : hovered
                      ? _darkBlue
                      : _normalBorder,
                  width: _borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: selected || hovered ? 0.12 : 0.06,
                    ),
                    blurRadius: selected || hovered ? 8 : 4,
                    offset: Offset(0, selected || hovered ? 4 : 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  SizedBox.expand(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.icon,
                          size: 32,
                          color: widget.enabled
                              ? _darkBlue
                              : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? _darkBlue
                                : const Color(0xFF1F2937),
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                        if (widget.description != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            widget.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: widget.enabled
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF),
                              fontSize: 11,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: _darkBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
