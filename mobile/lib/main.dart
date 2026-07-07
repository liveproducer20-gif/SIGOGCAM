import 'package:flutter/material.dart';

import 'core/thm/app_thm.dart';
import 'features/spl/spl_scr.dart';

void main() {
  runApp(const BitsacApp());
}

class BitsacApp extends StatelessWidget {
  const BitsacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plataforma SIGO-GCAM',
      debugShowCheckedModeBanner: false,
      theme: AppThm.lgt,
      home: SplScr(),
    );
  }
}