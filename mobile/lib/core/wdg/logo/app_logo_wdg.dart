import 'package:flutter/material.dart';

class AppLogoWdg extends StatelessWidget {
  final double sz;

  const AppLogoWdg({
    super.key,
    this.sz = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/img/logo_segura.png',
      width: sz,
      height: sz,
      fit: BoxFit.contain,
    );
  }
}