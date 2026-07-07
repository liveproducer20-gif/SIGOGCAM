import 'package:flutter/material.dart';

import '../../../../core/thm/app_thm.dart';
import '../../data/mdl/evt_tipo_mdl.dart';
import '../ctl/evt_new_ctl.dart';

class EvtInfStp extends StatefulWidget {
  final EvtNewCtl ctl;

  const EvtInfStp({
    super.key,
    required this.ctl,
  });

  @override
  State<EvtInfStp> createState() => _EvtInfStpState();
}

class _EvtInfStpState extends State<EvtInfStp> {
  final fechaCtl = TextEditingController();
  final horaIniCtl = TextEditingController();
  final horaFinCtl = TextEditingController();

  EvtNewCtl get ctl => widget.ctl;

  @override
  void initState() {
    super.initState();
    fechaCtl.text = ctl.mdl.fechaTxt;
    horaIniCtl.text = ctl.mdl.horaIni;
    horaFinCtl.text = ctl.mdl.horaFin;
  }

  @override
  void dispose() {
    fechaCtl.dispose();
    horaIniCtl.dispose();
    horaFinCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 920,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ListView(
              children: [
                const Text(
                  'Información General',
                  style: TextStyle(
                    color: AppThm.priClr,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: ctl.setNom,
                        decoration: InputDecoration(
                          labelText: 'Nombre del evento',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: FutureBuilder<List<EvtTipoMdl>>(
                        future: ctl.cargarTiposEvento(),
                        builder: (context, snapshot) {
                          final tipos = snapshot.data ?? [];

                          if (ctl.mdl.tipoId == null && tipos.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ctl.setTipo(tipos.first);
                            });
                          }

                          return DropdownButtonFormField<EvtTipoMdl>(
                            initialValue: tipos
                                    .where((e) => e.id == ctl.mdl.tipoId)
                                    .isNotEmpty
                                ? tipos.firstWhere((e) => e.id == ctl.mdl.tipoId)
                                : null,
                            decoration: InputDecoration(
                              labelText: snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? 'Cargando tipos...'
                                  : 'Tipo de evento',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: tipos
                                .map(
                                  (tipo) => DropdownMenuItem(
                                    value: tipo,
                                    child: Text(tipo.nombre),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) ctl.setTipo(v);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextField(
                  onChanged: ctl.setLugar,
                  decoration: InputDecoration(
                    labelText: 'Dirección GPS Google Maps',
                    hintText: 'Pega un link de Maps o escribe la direccion',
                    prefixIcon: const Icon(Icons.map_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fechaCtl,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: InputDecoration(
                          labelText: 'Fecha',
                          hintText: 'dd/mm/aaaa',
                          suffixIcon: IconButton(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: TextField(
                        controller: horaIniCtl,
                        readOnly: true,
                        onTap: () => _pickTime(isInicio: true),
                        decoration: InputDecoration(
                          labelText: 'Hora inicio',
                          hintText: '08:00',
                          suffixIcon: IconButton(
                            onPressed: () => _pickTime(isInicio: true),
                            icon: const Icon(Icons.schedule),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: TextField(
                        controller: horaFinCtl,
                        readOnly: true,
                        onTap: () => _pickTime(isInicio: false),
                        decoration: InputDecoration(
                          labelText: 'Hora fin',
                          hintText: '12:00',
                          suffixIcon: IconButton(
                            onPressed: () => _pickTime(isInicio: false),
                            icon: const Icon(Icons.schedule),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextField(
                  onChanged: ctl.setDesc,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: ctl.mdl.fecha ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (selected == null) return;

    final value = _formatDate(selected);
    fechaCtl.text = value;
    ctl.mdl.fecha = selected;
    ctl.setFechaTxt(value);
  }

  Future<void> _pickTime({required bool isInicio}) async {
    final initial = _parseTime(
      isInicio ? ctl.mdl.horaIni : ctl.mdl.horaFin,
    );
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (selected == null) return;

    final value = _formatTime(selected);
    if (isInicio) {
      horaIniCtl.text = value;
      ctl.setHoraIni(value);
    } else {
      horaFinCtl.text = value;
      ctl.setHoraFin(value);
    }
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }

    return const TimeOfDay(hour: 8, minute: 0);
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
