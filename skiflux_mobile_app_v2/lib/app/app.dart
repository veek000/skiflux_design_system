import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../features/auth/auth_flow.dart';

/// Root widget: wires the Skiflux theme to the screen flow.
class SkifluxMobileAppV2 extends StatelessWidget {
  const SkifluxMobileAppV2({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skiflux Mobile App V2',
      debugShowCheckedModeBanner: false,
      theme: SkifluxAppTheme.light,
      home: const AuthFlow(),
    );
  }
}
