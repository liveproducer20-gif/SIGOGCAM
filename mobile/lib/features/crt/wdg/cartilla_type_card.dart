import 'package:flutter/material.dart';

class CartillaTypeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const CartillaTypeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  State<CartillaTypeCard> createState() => _CartillaTypeCardState();
}

class _CartillaTypeCardState extends State<CartillaTypeCard> {
  bool _isHovered = false;

  static const Color _darkBlue = Color(0xFF1D3F73);
  static const Color _selectedBg = Color(0xFFEAF0F8);
  static const Color _normalBorder = Color(0xFFD1D5DB);

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final hovered = _isHovered && !selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          width: double.infinity,
          height: 128,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? _selectedBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _darkBlue
                  : hovered
                  ? _darkBlue
                  : _normalBorder,
              width: selected ? 2 : 1,
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
                    Icon(widget.icon, size: 32, color: _darkBlue),
                    const SizedBox(height: 10),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? _darkBlue : const Color(0xFF1F2937),
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
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
    );
  }
}
