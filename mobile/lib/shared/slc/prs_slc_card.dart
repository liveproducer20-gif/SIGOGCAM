import 'package:flutter/material.dart';

import '../../core/thm/app_thm.dart';
import 'prs_slc_mdl.dart';

class PrsSlcCard extends StatelessWidget {
  final PrsSlcMdl prs;
  final bool sel;
  final VoidCallback onTap;

  const PrsSlcCard({
    super.key,
    required this.prs,
    required this.sel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: sel ? 3 : 1,
      color: sel
          ? AppThm.secClr.withValues(alpha: 0.08)
          : Colors.white,
      child: ListTile(
        onTap: onTap,

        leading: CircleAvatar(
          backgroundColor: sel
              ? AppThm.secClr
              : AppThm.priClr,
          child: Text(
            prs.grado.substring(0, 1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        title: Text(
          prs.nom,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prs.grado),
            Text(
              '${prs.area} • ${prs.grupo}',
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ],
        ),

        trailing: sel
            ? const Icon(
                Icons.check_circle,
                color: AppThm.okClr,
              )
            : const Icon(
                Icons.add_circle_outline,
              ),
      ),
    );
  }
}