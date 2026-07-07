import 'package:flutter/material.dart';

class PriBtnWdg extends StatelessWidget {
  final String txt;
  final VoidCallback onTap;
  final IconData? icn;

  const PriBtnWdg({
    super.key,
    required this.txt,
    required this.onTap,
    this.icn,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: icn != null ? Icon(icn) : const SizedBox.shrink(),
        label: Text(txt),
      ),
    );
  }
}