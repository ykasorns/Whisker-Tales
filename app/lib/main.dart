import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wt_core/wt_core.dart';

import 'cloud/play_cloud.dart';
import 'iap/play_store.dart';
import 'ui/age_screen.dart';
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
    final saves = SaveService(HiveSaveStore(box));
    // Google Play Billing, listening from boot so no purchase is missed
    final store = PlayIapStore();
    // a save this build cannot load never stops the app: older slot or a
    // new game, with the broken save kept aside (bootGame)
    final boot = await bootGame(() => ProviderContainer(overrides: [
          ...content.overrides,
          saveServiceProvider.overrideWithValue(saves),
          iapStoreProvider.overrideWithValue(store),
          cloudStoreProvider.overrideWithValue(const PlayCloudStore()),
        ]));
    boot.container.read(iapServiceProvider)?.start();
    // cloud save before the game starts: waits at most a few seconds, never
    // changes the game after it is on screen (T-023)
    final cloud = await boot.container.read(cloudSyncProvider).sync();
    debugPrint('cloud save: ${cloud.name}');
    if (boot.error != null) debugPrint('save not loaded: ${boot.error}');
    runApp(UncontrolledProviderScope(
        container: boot.container,
        child: WhiskerTalesApp(
            avatarRules: content.avatar, saveFallback: boot.fallback)));
  } on ContentError catch (e) {
    runApp(BootErrorApp(message: '${e.file}\n${e.message}'));
  }
}

class WhiskerTalesApp extends ConsumerStatefulWidget {
  const WhiskerTalesApp(
      {super.key, this.avatarRules, this.lang = 'th', this.saveFallback});

  /// UI language (`th` / `en`).
  final String lang;

  /// Set when the newest save could not be loaded (told once on screen).
  final BootFallback? saveFallback;

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
      // save here, then up to the cloud unless it is further ahead
      onPause: () => ref
          .read(gameSaverProvider)
          .save()
          .then((_) => ref.read(cloudSyncProvider).push()),
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
      // above the Navigator, so dialogs and sheets get the language too
      builder: (context, child) => LangScope(lang: widget.lang, child: child!),
      home: widget.avatarRules == null
          ? const Scaffold(body: ColoredBox(color: Colors.black12))
          // first launch: the neutral age screen before anything else
          : ref.read(ageGateProvider).needsPrompt
              ? AgeScreen(onDone: () {
                  ref.read(gameSaverProvider).save(); // answered once
                  setState(() {});
                })
              : GameShell(
                  avatarRules: widget.avatarRules!,
                  saveFallback: widget.saveFallback),
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
