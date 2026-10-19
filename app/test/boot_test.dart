import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/main.dart';
import 'package:wt_core/wt_core.dart';

/// Reads the bundled copies straight from disk (no asset bundle in tests).
class DiskSource implements ContentSource {
  @override
  Future<String> read(String path) async =>
      File('assets/content/$path').readAsStringSync();
}

void main() {
  testWidgets('boot: data + save load, the app builds, pause saves',
      (tester) async {
    final store = MemorySaveStore();
    final content = await ContentRepository(DiskSource()).loadAll();
    final container = ProviderContainer(overrides: [
      ...content.overrides,
      saveServiceProvider.overrideWithValue(SaveService(store)),
    ]);
    addTearDown(container.dispose);
    expect((await container.read(gameSaverProvider).load()).document, isNull);

    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: const WhiskerTalesApp()));
    expect(tester.takeException(), isNull);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(store.data, isNotEmpty); // autosaved on pause
  });

  testWidgets('a data error is shown with the file', (tester) async {
    await tester.pumpWidget(
        const BootErrorApp(message: 'design/data/skills.json\nbad'));
    expect(find.textContaining('design/data/skills.json'), findsOneWidget);
  });
}
