import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/cnst/app_cnst.dart';
import '../../core/thm/app_thm.dart';
import '../../core/wdg/logo/app_logo_wdg.dart';
import '../auth/auth_scr.dart';


class SplScr extends StatefulWidget {
  const SplScr({super.key});

  @override
  State<SplScr> createState() => _SplScrState();
}

class _SplScrState extends State<SplScr> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => const AuthScr(),
  ),
);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThm.priClr,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogoWdg(sz: 150),
                const SizedBox(height: 28),
                const Text(
                  AppCnst.appNm,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  AppCnst.appDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  AppCnst.instNm,
                  style: TextStyle(
                    color: AppThm.accClr,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(
                  color: AppThm.accClr,
                ),
                const SizedBox(height: 20),
                Text(
                  'Versión ${AppCnst.appVer}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
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