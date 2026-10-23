import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/ui/game_icon.dart';

/// D-037: every emoji the game can show is either painted art or on the
/// explicit keep-as-text list, and every painted icon ships as a file.
final _emoji = RegExp(
    // ignore: valid_regexps (the analyzer does not know Extended_Pictographic)
    r'\p{Extended_Pictographic}️?(?:‍\p{Extended_Pictographic}️?)*'
    r'|[✓✗✕✖★]', unicode: true);

String _plain(String e) => e.replaceAll('️', '');

void main() {
  final j = jsonDecode(File('../design/art/icons.json').readAsStringSync())
      as Map<String, dynamic>;
  final mapped = {
    for (final k in (j['emoji'] as Map<String, dynamic>).keys) _plain(k),
  };
  final keep = {for (final k in (j['keep_as_text'] as List)) _plain('$k')};

  Iterable<File> sources() sync* {
    for (final d in ['lib', '../design/data']) {
      for (final f
          in Directory(d).listSync(recursive: true).whereType<File>()) {
        final p = f.path.replaceAll('\\', '/');
        if (p.contains('/gen/') || p.endsWith('game_icon.dart')) continue;
        // skills and road events are drawn by id (`skills` / `events` in
        // icons.json); their emoji is only the fallback
        if (p.endsWith('/skills.json') || p.endsWith('/road_events.json')) {
          continue;
        }
        if (p.endsWith('.dart') || p.endsWith('.json')) yield f;
      }
    }
    for (final f in Directory('lib/l10n').listSync().whereType<File>()) {
      if (f.path.endsWith('.arb')) yield f;
    }
  }

  test('every emoji in code, strings and data has art or is kept as text', () {
    final missing = <String>{};
    for (final f in sources()) {
      for (final line in f.readAsLinesSync()) {
        final t = line.trimLeft();
        if (f.path.endsWith('.dart') && t.startsWith('//')) continue;
        if (f.path.endsWith('.json') && line.contains('"_doc"')) continue;
        for (final m in _emoji.allMatches(line)) {
          final e = _plain(m.group(0)!);
          if (!mapped.contains(e) && !keep.contains(e)) {
            missing.add('$e  ${f.path}');
          }
        }
      }
    }
    expect(missing, isEmpty,
        reason: 'add these to design/art/icons.json (emoji or keep_as_text)');
  });

  test('every painted icon, skill and event art has its file', () {
    final ids = <String>{
      ...(j['emoji'] as Map<String, dynamic>).values.cast<String>(),
      ...(j['skills'] as List).cast<String>(),
      ...(j['events'] as List).map((e) => 'ev_$e'),
    };
    final absent = [
      for (final id in ids)
        if (!File('assets/game/icon/$id.png').existsSync()) id,
    ];
    expect(absent, isEmpty);
  });

  test('skill and road-event art ids match the data', () {
    final skills =
        jsonDecode(File('../design/data/skills.json').readAsStringSync())
            as Map<String, dynamic>;
    final events =
        jsonDecode(File('../design/data/road_events.json').readAsStringSync())
            as Map<String, dynamic>;
    final skillIds = {
      for (final s in skills['skills'] as List) (s as Map)['id']
    };
    final eventIds = {
      for (final s in events['events'] as List) (s as Map)['id']
    };
    expect({...(j['skills'] as List)}, skillIds);
    expect({...(j['events'] as List)}, eventIds);
  });

  testWidgets('IconText shows painted icons for mapped emoji, text otherwise',
      (tester) async {
    IconRegistry.setFromJson(j);
    addTearDown(IconRegistry.reset);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: Column(children: [
      IconText('🐟 12 ❤️'),
      IconText('plain words'),
      IconText('★ kept'),
    ]))));
    expect(find.byType(GameIcon), findsNWidgets(2));
    expect(find.text('plain words'), findsOneWidget);
    expect(find.textContaining('★'), findsOneWidget);
  });

  test('no Material icons in the UI — every icon is the game\'s own art', () {
    final offenders = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (f.path.contains('/gen/')) continue;
      final src = f.readAsStringSync();
      if (RegExp(r'\bIcons\.\w+').hasMatch(src)) offenders.add(f.path);
    }
    expect(offenders, isEmpty, reason: 'use GameIcon / IconText (D-037)');
  });
}
