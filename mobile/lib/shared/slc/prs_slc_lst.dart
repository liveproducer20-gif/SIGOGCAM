import 'package:flutter/material.dart';

import 'prs_slc_card.dart';
import 'prs_slc_mdl.dart';

class PrsSlcLst extends StatelessWidget {
  final List<PrsSlcMdl> items;
  final List<PrsSlcMdl> selItems;
  final ValueChanged<PrsSlcMdl> onTap;

  const PrsSlcLst({
    super.key,
    required this.items,
    required this.selItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final prs = items[i];
        final sel = selItems.any((e) => e.id == prs.id);

        return PrsSlcCard(
          prs: prs,
          sel: sel,
          onTap: () => onTap(prs),
        );
      },
    );
  }
}