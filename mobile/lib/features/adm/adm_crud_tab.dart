import 'package:flutter/material.dart';

import 'adm_api.dart';

abstract class AdmCrudTab extends StatefulWidget {
  final AdmApi api;
  const AdmCrudTab({super.key, required this.api});
}
