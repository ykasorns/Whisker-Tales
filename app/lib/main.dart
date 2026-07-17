import 'package:flutter/material.dart';
import 'package:wt_core/wt_core.dart';

import 'modes.dart';

void main() {
  registerModes();
  runApp(const WhiskerTalesApp());
}

class WhiskerTalesApp extends StatelessWidget {
  const WhiskerTalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whisker Tales',
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: (AppLayout.gameViewportRatio * 100).round(),
                child: const ColoredBox(color: Colors.black12),
              ),
              Expanded(
                flex: (AppLayout.uiPanelRatio * 100).round(),
                child: const ColoredBox(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
