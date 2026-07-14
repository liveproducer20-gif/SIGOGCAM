import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/evt/ann/mdl/ann_mdl.dart';
import 'package:mobile/features/evt/ann/wdg/ann_card_wdg.dart';

void main() {
  testWidgets('announcement card paints rounded priority accent on web',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final announcement = AnnMdl(
      id: 1,
      ttl: 'Comunicado institucional',
      desc: 'Contenido de prueba para validar el renderizado de la tarjeta.',
      img: 'assets/img/auth_bg.jpg',
      fecPub: DateTime(2026, 7, 14, 9, 30),
      prioridad: 'Importante',
      publicado: true,
      notificar: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 1200,
              child: AnnCardWdg(
                ann: announcement,
                canManage: true,
                onEdit: () {},
                onToggle: () {},
                onDelete: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(AnnCardWdg)));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    await mouse.removePointer();
  });
}
