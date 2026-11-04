import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/modes.dart';
import 'package:wt_core/wt_core.dart';

class _Assets implements ContentSource {
  @override
  Future<String> read(String path) =>
      rootBundle.loadString('assets/content/$path');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('story and the dungeon register from their bundled manifests',
      () async {
    final content = await ContentRepository(_Assets()).loadAll();
    final registry =
        await registerModes(content.story, await loadDungeonJson(_Assets()));
    expect(registry.modes.map((m) => m.id), ['story', 'dungeon']);
    expect(registry.enabledModes.map((m) => m.id), ['story', 'dungeon']);
  });
}
