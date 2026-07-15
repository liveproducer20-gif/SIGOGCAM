import 'package:flutter/material.dart';

class CartillaTypeItem {
  final String id;
  final String title;
  final IconData icon;
  final bool requiresFormationPermission;

  const CartillaTypeItem({
    required this.id,
    required this.title,
    required this.icon,
    this.requiresFormationPermission = false,
  });

  static const List<CartillaTypeItem> all = [
    CartillaTypeItem(
      id: 'formacion_entrante',
      title: 'Formación entrante',
      icon: Icons.login_outlined,
      requiresFormationPermission: true,
    ),
    CartillaTypeItem(
      id: 'formacion_saliente',
      title: 'Formación saliente',
      icon: Icons.logout_outlined,
      requiresFormationPermission: true,
    ),
    CartillaTypeItem(
      id: 'otras_cartillas',
      title: 'Otras cartillas',
      icon: Icons.dashboard_customize_outlined,
    ),
    CartillaTypeItem(
      id: 'desalojo_vendedores',
      title: 'Desalojo de vendedores\nautónomos no regularizados',
      icon: Icons.storefront_outlined,
    ),
    CartillaTypeItem(
      id: 'punto_martillo',
      title: 'Punto martillo',
      icon: Icons.gavel_outlined,
    ),
    CartillaTypeItem(
      id: 'rondas_disuasivas',
      title: 'Rondas disuasivas',
      icon: Icons.directions_walk_outlined,
    ),
    CartillaTypeItem(
      id: 'retiro_temporal',
      title: 'Retiro temporal',
      icon: Icons.backup_outlined,
    ),
    CartillaTypeItem(
      id: 'radioperador',
      title: 'Radioperador',
      icon: Icons.radio_outlined,
    ),
    CartillaTypeItem(
      id: 'supervision',
      title: 'Supervisión',
      icon: Icons.visibility_outlined,
    ),
    CartillaTypeItem(
      id: 'colaboracion_entidades',
      title: 'Colaboración con\notras entidades',
      icon: Icons.groups_outlined,
    ),
    CartillaTypeItem(
      id: 'colaboracion_ciudadana',
      title: 'Colaboración\nciudadana',
      icon: Icons.people_outlined,
    ),
  ];
}
