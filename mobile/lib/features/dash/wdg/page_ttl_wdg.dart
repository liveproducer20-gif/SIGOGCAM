import 'package:flutter/material.dart';

import '../../../core/thm/app_thm.dart';

class PageTtlWdg extends StatelessWidget {
  final String ttl;
  final String sub;

  const PageTtlWdg({
    super.key,
    required this.ttl,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          ttl,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: AppThm.priClr,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          sub,
          style: const TextStyle(
            fontSize: 17,
            color: Colors.black54,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 28),

        Container(
          width: 90,
          height: 5,
          decoration: BoxDecoration(
            color: AppThm.secClr,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }
}