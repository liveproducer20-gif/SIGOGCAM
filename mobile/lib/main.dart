import 'package:flutter/material.dart';

import 'core/auth/auth_session.dart';
import 'core/thm/app_thm.dart';
import 'features/spl/spl_scr.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.init();
  runApp(const BitsacApp());
}

class BitsacApp extends StatelessWidget {
  const BitsacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plataforma SIGO - Sistema Inteligente de Gestión Operativa',
      debugShowCheckedModeBanner: false,
      theme: AppThm.lgt,
      home: SplScr(),
    );
  }
}