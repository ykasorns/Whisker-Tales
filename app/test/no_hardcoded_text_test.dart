import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T-004 AC: no UI text written into widgets — words come from the arb
/// files. Numbers, emoji and symbols are fine. Allowed exceptions: the dev
/// telemetry overlay (never in release) and the boot error screen (shown
/// before any language is loaded).
void main() {
  test('no hard-coded words in Text / TextSpan / labels', () {
    const allowed = {'lib/debug/telemetry.dart'};
    const allowedText = {
      'Whisker Tales', // the game's name, the same in every language
      r'Game data error\n\n$message', // boot failed: no language loaded
    };
    // a word: 2+ Latin letters or any Thai letter
    final word = RegExp(r'[A-Za-z]{2,}|[฀-๿]');
    final literal = RegExp(
        r"""(?:\bText\(|TextSpan\(\s*text:|\blabel:|\btooltip:|\btitle:)\s*'((?:[^'\\]|\\.)*)'""");
    final bad = <String>[];
    for (final f
        in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = f.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart') ||
          path.startsWith('lib/l10n/') ||
          allowed.contains(path)) {
        continue;
      }
      final src = f.readAsStringSync();
      for (final m in literal.allMatches(src)) {
        // interpolated values (${...}) are data, not words
        final text = m.group(1)!.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
        if (word.hasMatch(text) && !allowedText.contains(m.group(1))) {
          final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
          bad.add('$path:$line  ${m.group(0)}');
        }
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });
}
