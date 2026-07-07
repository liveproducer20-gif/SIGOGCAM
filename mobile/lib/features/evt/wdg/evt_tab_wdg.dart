import 'package:flutter/material.dart';

import '../../../core/thm/app_thm.dart';

class EvtTabWdg extends StatelessWidget {
  const EvtTabWdg({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              isScrollable: true,
              indicatorColor: AppThm.secClr,
              labelColor: AppThm.priClr,
              unselectedLabelColor: Colors.black54,
              tabs: [
                Tab(
                  icon: Icon(Icons.info_outline),
                  text: 'Información',
                ),
                Tab(
                  icon: Icon(Icons.groups_outlined),
                  text: 'Convocados',
                ),
                Tab(
                  icon: Icon(Icons.verified_user_outlined),
                  text: 'Confirmaciones',
                ),
                Tab(
                  icon: Icon(Icons.fact_check_outlined),
                  text: 'Asistencia',
                ),
                Tab(
                  icon: Icon(Icons.account_tree_outlined),
                  text: 'Distribución',
                ),
                Tab(
                  icon: Icon(Icons.history),
                  text: 'Historial',
                ),
                Tab(
                  icon: Icon(Icons.campaign_outlined),
                  text: 'Comunicaciones',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _tab('Información General'),
                _tab('Personal Convocado'),
                _tab('Confirmaciones'),
                _tab('Asistencia'),
                _tab('Distribución'),
                _tab('Historial'),
                _tabBloqueado(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _tab(String titulo) {
    return Center(
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AppThm.priClr,
        ),
      ),
    );
  }

  static Widget _tabBloqueado() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 70,
            color: Colors.black38,
          ),
          SizedBox(height: 20),
          Text(
            'Disponible para el rol Comunicaciones',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppThm.priClr,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Se habilitará cuando se implemente el módulo correspondiente.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}