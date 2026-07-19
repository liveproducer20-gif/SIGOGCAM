import 'package:flutter/material.dart';

import '../../../core/thm/app_thm.dart';
import '../../../core/wdg/responsive.dart';

class PageTtlWdg extends StatelessWidget {
  final String ttl;
  final String sub;

  const PageTtlWdg({super.key, required this.ttl, required this.sub});

  @override
  Widget build(BuildContext context) {
    final mobile = AppResponsive.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ttl,
          style: TextStyle(
            fontSize: AppResponsive.titleFontSize(context),
            fontWeight: FontWeight.bold,
            color: AppThm.priClr,
          ),
        ),

        SizedBox(height: mobile ? 6 : 10),

        Text(
          sub,
          style: TextStyle(
            fontSize: AppResponsive.subtitleFontSize(context),
            color: Colors.black54,
            height: 1.4,
          ),
        ),

        SizedBox(height: mobile ? 16 : 28),

        Container(
          width: mobile ? 64 : 90,
          height: 4,
          decoration: BoxDecoration(
            color: AppThm.secClr,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }
}
