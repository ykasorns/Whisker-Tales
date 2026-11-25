import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'ui/battle_fx.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wt_core/wt_core.dart';

import 'audio/player_output.dart';
import 'platform/platform_services.dart';
import 'ui/age_screen.dart';
import 'ui/frames.dart';
import 'ui/game_icon.dart';
import 'ui/yarn_basket.dart';
import 'ui/game_shell.dart';
import 'ui/palette.dart';
import 'ui/portrait_frame.dart';
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
  try {
    final content =
        await ContentRepository(const AssetContentSource()).loadAll();
    final modes = await registerModes(
        content.story, await loadDungeonJson(const AssetContentSource()));
    try {
      await IconRegistry.load(); // painted icons replace the emoji (D-037)
    } catch (e) {
      debugPrint('icons.json not loaded, showing emoji: $e'); // never a hole
    }
    try {
      await FrameArt.load(); // painted UI frames (D-059)
    } catch (e) {
      debugPrint('ui_frames.json not loaded, plain boxes: $e');
    }
    try {
      await BasketArt.load(); // the home basket (D-040)
    } catch (e) {
      debugPrint('basket art not loaded, showing the yarn ball: $e');
    }
    await Hive.initFlutter();
    final box = await Hive.openBox<String>('whisker_tales_save');
    final saves = SaveService(HiveSaveStore(box));
    // Play Billing, Play Games and AdMob on Android; none on the web. Made
    // once: Billing listens from boot so no purchase is missed, and bootGame
    // may build the container twice.
    final platform = platformOverrides();
    // a save this build cannot load never stops the app: older slot or a
    // new game, with the broken save kept aside (bootGame)
    final boot = await bootGame(() => ProviderContainer(overrides: [
          ...content.overridesWith(adsOff: !platformHasAds),
          modeRegistryProvider.overrideWithValue(modes),
          avatarRulesProvider.overrideWithValue(content.avatar),
          saveServiceProvider.overrideWithValue(saves),
          ...platform,
          // real playback of music + effects (T-024)
          audioOutputProvider.overrideWithValue(PlayerAudioOutput()),
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
      {super.key, this.avatarRules, this.lang, this.saveFallback});

  /// Fixed UI language (`th` / `en`) for tests; null = the player's choice
  /// (`langProvider`, saved in settings).
  final String? lang;

  /// Set when the newest save could not be loaded (told once on screen).
  final BootFallback? saveFallback;

  /// Null in tests that don't load sprites.
  final AvatarRules? avatarRules;

  @override
  ConsumerState<WhiskerTalesApp> createState() => _WhiskerTalesAppState();
}

class _WhiskerTalesAppState extends ConsumerState<WhiskerTalesApp> {
  late final AppLifecycleListener _lifecycle;

  /// Web only: a browser tab can be closed or reloaded without the app ever
  /// pausing, so progress is also saved on a timer and when the tab hides.
  Timer? _autosave;
  static const autosaveEvery = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    if (kIsWeb && widget.avatarRules != null) {
      _autosave = Timer.periodic(
          autosaveEvery, (_) => ref.read(gameSaverProvider).save());
    }
    // Save when the app goes to the background; check the offline window
    // when it comes back (the "welcome back" screen is T-042).
    _lifecycle = AppLifecycleListener(
      // save here, then up to the cloud unless it is further ahead
      onPause: () => ref
          .read(gameSaverProvider)
          .save()
          .then((_) => ref.read(cloudSyncProvider).push()),
      onHide: kIsWeb ? () => ref.read(gameSaverProvider).save() : null,
    );
  }

  @override
  void dispose() {
    _autosave?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whisker Tales',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // the web has no system Thai font: use the bundled one
        fontFamily: kIsWeb ? 'NotoSansThai' : null,
        scaffoldBackgroundColor: Palette.paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Palette.mochi,
          primary: Palette.coral,
          secondary: Palette.teal,
          surface: Palette.parchment,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            foregroundColor: Palette.ink,
            backgroundColor: Palette.sun,
            disabledBackgroundColor: Palette.sheet,
            disabledForegroundColor: Palette.inkSoft,
            elevation: 3,
            shadowColor: Palette.coral.withValues(alpha: .34),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(22)),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Palette.inkSoft,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Palette.parchment,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
        ),
      ),
      // T-004: arb strings; the language switches at runtime (settings)
      locale: Locale(widget.lang ?? ref.watch(langProvider)),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // wide screens (web on a desktop): an upright frame for now
      builder: (context, child) =>
          PortraitFrame(child: child ?? const SizedBox()),
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
