import 'package:flutter/material.dart';

import '../../../../core/thm/app_thm.dart';
import '../../../../shared/slc/prs_slc_dlg.dart';
import '../../../../shared/slc/prs_slc_mdl.dart';
import '../ctl/evt_new_ctl.dart';

class EvtPrsStp extends StatefulWidget {
  final EvtNewCtl ctl;

  const EvtPrsStp({
    super.key,
    required this.ctl,
  });

  @override
  State<EvtPrsStp> createState() => _EvtPrsStpState();
}

class _EvtPrsStpState extends State<EvtPrsStp> {
  EvtNewCtl get ctl => widget.ctl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 920,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Convocados',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Seleccione el personal que sera convocado al evento.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () async {
                    final result = await showDialog<List<PrsSlcMdl>>(
                      context: context,
                      builder: (_) => PrsSlcDlg(
                        initialIds: ctl.mdl.prsIds,
                      ),
                    );

                    if (result != null) {
                      ctl.setPrsItems(result);
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Seleccionar personal'),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ctl.mdl.prsItems.isEmpty
                        ? const Center(
                            child: Text(
                              'Aun no se ha seleccionado personal.',
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal asignado: ${ctl.mdl.prsItems.length}',
                                style: const TextStyle(
                                  color: AppThm.priClr,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: ctl.mdl.prsItems.length,
                                  separatorBuilder: (_, _) =>
                                      const Divider(height: 1),
                                  itemBuilder: (_, i) {
                                    final prs = ctl.mdl.prsItems[i];

                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.check_circle,
                                        color: AppThm.okClr,
                                      ),
                                      title: Text(prs.nom),
                                      subtitle:
                                          Text('${prs.area} - ${prs.grupo}'),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
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
