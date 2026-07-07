import 'package:flutter/material.dart';

class LoadWdg extends StatelessWidget {
  const LoadWdg({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}