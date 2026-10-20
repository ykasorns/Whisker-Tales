import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wt_core/wt_core.dart';

import 'ui/game_shell.dart';
import 'l10n/strings.dart';
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
  // the game is designed for a phone held upright (60/40 layout)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
        container: container,
        child: WhiskerTalesApp(avatarRules: content.avatar)));
  } on ContentError catch (e) {
    runApp(BootErrorApp(message: '${e.file}\n${e.message}'));
  }
}

class WhiskerTalesApp extends ConsumerStatefulWidget {
  const WhiskerTalesApp({super.key, this.avatarRules, this.lang = 'th'});

  /// UI language (`th` / `en`).
  final String lang;

  /// Null in tests that don't load sprites.
  final AvatarRules? avatarRules;

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFFBF2),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF6A83C)),
      ),
      home: LangScope(
        lang: widget.lang,
        child: widget.avatarRules == null
            ? const Scaffold(body: ColoredBox(color: Colors.black12))
            : GameShell(avatarRules: widget.avatarRules!),
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
