import 'package:flutter/material.dart';

import '../../../core/thm/app_thm.dart';
import '../mdl/crt_type_item.dart';
import 'cartilla_type_card.dart';

class CartillaTypeSelector extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final bool canView;
  final bool canCreateFormation;

  const CartillaTypeSelector({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.canView = false,
    this.canCreateFormation = false,
  });

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de cartilla',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppThm.priClr,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final cols = maxWidth >= 620 ? 3 : (maxWidth >= 400 ? 2 : 1);
            final cardWidth = (maxWidth - gap * (cols - 1)) / cols;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final item in CartillaTypeItem.all)
                  SizedBox(
                    width: cardWidth,
                    child: CartillaTypeCard(
                      icon: item.icon,
                      title: item.title,
                      selected: selectedId == item.id,
                      enabled: item.requiresFormationPermission
                          ? canCreateFormation
                          : canView,
                      onTap: () => onSelected(item.id),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
