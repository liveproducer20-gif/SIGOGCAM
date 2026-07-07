import 'package:flutter/material.dart';

class SecTtlWdg extends StatelessWidget {
  final String ttl;

  const SecTtlWdg({
    super.key,
    required this.ttl,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      ttl,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}