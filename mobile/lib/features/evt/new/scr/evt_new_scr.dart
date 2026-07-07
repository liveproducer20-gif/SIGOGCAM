import 'package:flutter/material.dart';

import '../../../../core/thm/app_thm.dart';
import '../ctl/evt_new_ctl.dart';
import '../stp/evt_inf_stp.dart';
import '../stp/evt_pre_stp.dart';
import '../stp/evt_prs_stp.dart';
import '../stp/evt_pub_stp.dart';
import '../stp/evt_val_stp.dart';
import '../wdg/evt_nav_wdg.dart';
import '../wdg/evt_stepper_wdg.dart';

class EvtNewScr extends StatefulWidget {
  final int creadoPor;

  const EvtNewScr({
    super.key,
    required this.creadoPor,
  });

  @override
  State<EvtNewScr> createState() => _EvtNewScrState();
}

class _EvtNewScrState extends State<EvtNewScr> {
  int idx = 0;
  bool saving = false;

  late final EvtNewCtl ctl;

  @override
  void initState() {
    super.initState();
    ctl = EvtNewCtl(creadoPor: widget.creadoPor);
  }

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  List<Widget> get pages => [
        EvtInfStp(ctl: ctl),
        EvtPrsStp(ctl: ctl),
        EvtPubStp(ctl: ctl),
        EvtPreStp(ctl: ctl),
        EvtValStp(ctl: ctl),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThm.bgClr,
      appBar: AppBar(
        title: const Text('Nuevo Evento'),
      ),
      body: Column(
        children: [
          EvtStepperWdg(idx: idx),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: pages[idx],
            ),
          ),
          EvtNavWdg(
            idx: idx,
            total: pages.length,
            saving: saving,
            onBack: () {
              if (idx > 0) {
                setState(() => idx--);
              } else {
                Navigator.pop(context);
              }
            },
            onNext: _next,
          ),
        ],
      ),
    );
  }

  Future<void> _next() async {
    if (idx < pages.length - 1) {
      setState(() => idx++);
      return;
    }

    setState(() => saving = true);

    try {
      _showCreatingDialog();
      await Future.delayed(const Duration(seconds: 3));
      await ctl.crearEvento();

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento creado correctamente')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _showCreatingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 18),
            Text('Creando evento...'),
          ],
        ),
      ),
    );
  }
}
