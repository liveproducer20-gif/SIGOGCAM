import 'package:flutter/material.dart';

import '../../adm/adm_design_tokens.dart';

class EvtFilWdg extends StatefulWidget {
  final ValueChanged<String> onBuscar;
  final ValueChanged<String> onEstado;
  final ValueChanged<String> onTipo;
  final ValueChanged<String>? onLugar;
  final ValueChanged<String>? onPrioridad;
  final ValueChanged<DateTime?>? onFecha;
  final bool admin;

  const EvtFilWdg({
    super.key,
    required this.onBuscar,
    required this.onEstado,
    required this.onTipo,
    this.onLugar,
    this.onPrioridad,
    this.onFecha,
    this.admin = false,
  });

  @override
  State<EvtFilWdg> createState() => _EvtFilWdgState();
}

class _EvtFilWdgState extends State<EvtFilWdg> {
  final searchCtl = TextEditingController();
  final placeCtl = TextEditingController();
  String estado = 'Todos';
  String tipo = 'Todos';
  String prioridad = 'Todas';
  DateTime? fecha;

  @override
  void dispose() {
    searchCtl.dispose();
    placeCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
    final width = c.maxWidth >= 1050 ? (c.maxWidth - 14 * (widget.admin ? 5 : 4)) / (widget.admin ? 6 : 5) : c.maxWidth >= 620 ? (c.maxWidth - 14) / 2 : c.maxWidth;
    return Wrap(spacing: 14, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
      SizedBox(width: c.maxWidth >= 1050 ? width * 1.35 : width, child: _field(TextField(controller: searchCtl, onChanged: widget.onBuscar, decoration: const InputDecoration(hintText: 'Buscar evento...', prefixIcon: Icon(Icons.search_rounded))))),
      SizedBox(width: width, child: _field(DropdownButtonFormField<String>(initialValue: estado, isExpanded: true, decoration: const InputDecoration(labelText: 'Estado'), items: const ['Todos','PLANIFICADO','EN_CURSO','FINALIZADO','CANCELADO'].map((v) => DropdownMenuItem(value: v, child: Text(v == 'EN_CURSO' ? 'En curso' : _title(v)))).toList(), onChanged: (v) { if (v != null) { setState(() => estado = v); widget.onEstado(v); } }))),
      SizedBox(width: width, child: _field(DropdownButtonFormField<String>(initialValue: tipo, isExpanded: true, decoration: const InputDecoration(labelText: 'Tipo'), items: const ['Todos','Capacitacion','Curso','Reunion','Operativo','Otro'].map((v) => DropdownMenuItem(value: v, child: Text(_label(v)))).toList(), onChanged: (v) { if (v != null) { setState(() => tipo = v); widget.onTipo(v); } }))),
      SizedBox(width: width, child: _field(InkWell(onTap: _pickDate, child: InputDecorator(decoration: const InputDecoration(labelText: 'Fecha', suffixIcon: Icon(Icons.calendar_month_outlined)), child: Text(fecha == null ? 'Todas' : '${fecha!.day.toString().padLeft(2,'0')}/${fecha!.month.toString().padLeft(2,'0')}/${fecha!.year}', overflow: TextOverflow.ellipsis))))),
      SizedBox(width: width, child: _field(TextField(controller: placeCtl, onChanged: widget.onLugar, decoration: const InputDecoration(labelText: 'Lugar', prefixIcon: Icon(Icons.location_on_outlined))))),
      if (widget.admin) SizedBox(width: width, child: _field(DropdownButtonFormField<String>(initialValue: prioridad, isExpanded: true, decoration: const InputDecoration(labelText: 'Prioridad'), items: const ['Todas','Normal','Importante','Urgente'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) { setState(() => prioridad = v); widget.onPrioridad?.call(v); } }))),
      TextButton.icon(onPressed: _clear, icon: const Icon(Icons.filter_alt_off_outlined), label: const Text('Limpiar filtros')),
    ]);
  });

  Widget _field(Widget child) => Theme(data: Theme.of(context).copyWith(inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: AdmTokens.grey50, contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AdmTokens.grey200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AdmTokens.secondary)))), child: child);

  Future<void> _pickDate() async {
    final value = await showDatePicker(context: context, initialDate: fecha ?? DateTime.now(), firstDate: DateTime(DateTime.now().year - 2), lastDate: DateTime(DateTime.now().year + 5));
    if (value != null) { setState(() => fecha = value); widget.onFecha?.call(value); }
  }

  void _clear() {
    searchCtl.clear(); placeCtl.clear();
    setState(() { estado = 'Todos'; tipo = 'Todos'; prioridad = 'Todas'; fecha = null; });
    widget.onBuscar(''); widget.onEstado('Todos'); widget.onTipo('Todos'); widget.onLugar?.call(''); widget.onPrioridad?.call('Todas'); widget.onFecha?.call(null);
  }
}

String _title(String value) => value[0] + value.substring(1).toLowerCase();
String _label(String value) => switch (value) { 'Capacitacion' => 'Capacitación', 'Reunion' => 'Reunión', _ => _title(value) };
