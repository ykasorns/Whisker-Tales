import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

/// The bundled copies must match design/ — run tools/sync_content.sh.
void main() {
  test('bundled game data matches design/', () {
    for (final path in ContentRepository.files.keys) {
      final source = File('../$path').readAsStringSync();
      final bundled = File('assets/content/$path');
      expect(bundled.existsSync(), isTrue,
          reason: '$path missing — run tools/sync_content.sh');
      expect(bundled.readAsStringSync(), source,
          reason: '$path is stale — run tools/sync_content.sh');
    }
  });
}
