import 'package:flutter/material.dart';
import 'dart:math';

import '../../core/thm/app_thm.dart';
import '../../features/evt/data/repository/evt_repository.dart';
import 'prs_slc_lst.dart';
import 'prs_slc_mdl.dart';

class PrsSlcDlg extends StatefulWidget {
  final List<int> initialIds;

  const PrsSlcDlg({
    super.key,
    this.initialIds = const [],
  });

  @override
  State<PrsSlcDlg> createState() => _PrsSlcDlgState();
}

class _PrsSlcDlgState extends State<PrsSlcDlg> {
  final txtCtl = TextEditingController();
  final repository = EvtRepository();
  final List<PrsSlcMdl> selLst = [];

  late final Future<List<PrsSlcMdl>> prsFuture;
  String filtro = '';
  String areaFiltro = 'Todas';
  String grupoFiltro = 'Todos';
  final cantCtl = TextEditingController();
  bool initialLoaded = false;

  @override
  void initState() {
    super.initState();
    prsFuture = repository.obtenerPersonalOperativo();
    txtCtl.addListener(() {
      setState(() => filtro = txtCtl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    txtCtl.dispose();
    cantCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 1050,
        height: 650,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.groups, color: AppThm.priClr),
                  SizedBox(width: 10),
                  Text(
                    'Seleccionar Personal',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppThm.priClr,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: txtCtl,
                decoration: InputDecoration(
                  hintText: 'Buscar personal...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<PrsSlcMdl>>(
                  future: prsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'No se pudo cargar el personal: ${snapshot.error}',
                        ),
                      );
                    }

                    final prsLst = snapshot.data ?? [];
                    _loadInitialSelection(prsLst);
                    final visibleLst = _filter(prsLst);
                    final areas = _options(
                      prsLst.map((e) => e.area),
                      'Todas',
                    );
                    final grupos = _options(
                      prsLst.map((e) => e.grupo),
                      'Todos',
                    );

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: areaFiltro,
                                decoration: InputDecoration(
                                  labelText: 'Area operativa',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: areas
                                    .map(
                                      (area) => DropdownMenuItem(
                                        value: area,
                                        child: Text(area),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => areaFiltro = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: grupoFiltro,
                                decoration: InputDecoration(
                                  labelText: 'Grupo',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: grupos
                                    .map(
                                      (grupo) => DropdownMenuItem(
                                        value: grupo,
                                        child: Text(grupo),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => grupoFiltro = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: cantCtl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Cantidad',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: () => _selectRandom(visibleLst),
                              icon: const Icon(Icons.shuffle),
                              label: const Text('Aleatorio'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () => _selectVisible(visibleLst),
                              icon: const Icon(Icons.playlist_add_check),
                              label: const Text('Seleccionar visibles'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: PrsSlcLst(
                                  items: visibleLst,
                                  selItems: selLst,
                                  onTap: _toggle,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 2,
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Personal seleccionado',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppThm.priClr,
                                          ),
                                        ),
                                        const Divider(),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: selLst.length,
                                            itemBuilder: (_, i) {
                                              final prs = selLst[i];

                                              return ListTile(
                                                leading: const Icon(
                                                  Icons.check_circle,
                                                  color: AppThm.okClr,
                                                ),
                                                title: Text(prs.nom),
                                                subtitle: Text(
                                                  '${prs.area} - ${prs.grupo}',
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const Divider(),
                                        Text(
                                          'Total seleccionados: ${selLst.length}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, selLst),
                    icon: const Icon(Icons.check),
                    label: const Text('Aceptar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadInitialSelection(List<PrsSlcMdl> prsLst) {
    if (initialLoaded) return;

    selLst.addAll(
      prsLst.where((prs) => widget.initialIds.contains(prs.id)),
    );
    initialLoaded = true;
  }

  List<PrsSlcMdl> _filter(List<PrsSlcMdl> prsLst) {
    return prsLst.where((prs) {
      final matchTexto = filtro.isEmpty ||
          prs.nom.toLowerCase().contains(filtro) ||
          prs.ced.toLowerCase().contains(filtro) ||
          prs.area.toLowerCase().contains(filtro) ||
          prs.grupo.toLowerCase().contains(filtro);
      final matchArea = areaFiltro == 'Todas' || prs.area == areaFiltro;
      final matchGrupo = grupoFiltro == 'Todos' || prs.grupo == grupoFiltro;

      return matchTexto && matchArea && matchGrupo;
    }).toList();
  }

  List<String> _options(Iterable<String> values, String first) {
    final clean = values.where((e) => e.trim().isNotEmpty).toSet().toList()
      ..sort();
    return [first, ...clean];
  }

  void _toggle(PrsSlcMdl prs) {
    setState(() {
      final existe = selLst.any((e) => e.id == prs.id);

      if (existe) {
        selLst.removeWhere((e) => e.id == prs.id);
      } else {
        selLst.add(prs);
      }
    });
  }

  void _selectVisible(List<PrsSlcMdl> visibleLst) {
    setState(() {
      for (final prs in visibleLst) {
        if (!selLst.any((e) => e.id == prs.id)) {
          selLst.add(prs);
        }
      }
    });
  }

  void _selectRandom(List<PrsSlcMdl> visibleLst) {
    final qty = int.tryParse(cantCtl.text.trim()) ?? 0;
    if (qty <= 0 || visibleLst.isEmpty) return;

    final pool = [...visibleLst]..shuffle(Random());
    final selected = pool.take(qty).toList();

    setState(() {
      selLst
        ..clear()
        ..addAll(selected);
    });
  }
}
