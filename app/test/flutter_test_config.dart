import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests draw Latin text with the real Roboto (the font the game gets on
/// Android), not the test font's boxes: a label that does not fit its button
/// on a phone must not fit in a golden either. Thai still draws as boxes.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = Platform.environment['FLUTTER_ROOT'];
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (root != null && dir.existsSync()) {
    final loader = FontLoader('Roboto');
    for (final f in dir.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (name.startsWith('Roboto-') && name.endsWith('.ttf')) {
        loader.addFont(
            f.readAsBytes().then((b) => ByteData.sublistView(b)));
      }
    }
    await loader.load();
  }
  await testMain();
}
