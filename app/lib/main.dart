import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wt_core/wt_core.dart';

import 'modes.dart';

/// Reads game data from the app bundle (copied by tools/sync_content.sh).
class AssetContentSource implements ContentSource {
  const AssetContentSource();

  @override
  Future<String> read(String path) =>
      rootBundle.loadString('assets/content/$path');
}

/// Boot (T-003, T-022): data → local save → game. A data error stops here
/// with the file and field on screen instead of running on bad numbers.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerModes();
  try {
    final content =
        await ContentRepository(const AssetContentSource()).loadAll();
    await Hive.initFlutter();
    final box = await Hive.openBox<String>('whisker_tales_save');
    final container = ProviderContainer(overrides: [
      ...content.overrides,
      saveServiceProvider.overrideWithValue(SaveService(HiveSaveStore(box))),
    ]);
    await container.read(gameSaverProvider).load();
    runApp(UncontrolledProviderScope(
        container: container, child: const WhiskerTalesApp()));
  } on ContentError catch (e) {
    runApp(BootErrorApp(message: '${e.file}\n${e.message}'));
  }
}

class WhiskerTalesApp extends ConsumerStatefulWidget {
  const WhiskerTalesApp({super.key});

  @override
  ConsumerState<WhiskerTalesApp> createState() => _WhiskerTalesAppState();
}

class _WhiskerTalesAppState extends ConsumerState<WhiskerTalesApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Save when the app goes to the background; check the offline window
    // when it comes back (the "welcome back" screen is T-042).
    _lifecycle = AppLifecycleListener(
      onPause: () => ref.read(gameSaverProvider).save(),
      onResume: () => ref.read(offlineRewardProvider).checkIn(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

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

/// Shown when game data fails validation — a build problem, not a player
/// one, so it is plain and technical.
class BootErrorApp extends StatelessWidget {
  const BootErrorApp({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Game data error\n\n$message',
                  textAlign: TextAlign.center),
            ),
          ),
        ),
      );
}
