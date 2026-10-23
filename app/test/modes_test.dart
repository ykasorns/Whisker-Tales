import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/modes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('story registers from its bundled manifest and ships dormant',
      () async {
    final registry = await registerModes();
    expect(registry.modes.map((m) => m.id), ['story']);
    expect(registry.enabledModes, isEmpty);
  });
}
