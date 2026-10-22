import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart';
import 'package:wt_core/wt_core.dart';

/// Play Games Services saved game as the cloud slot (T-023, D-017, D-025).
/// Switched on only when the build has a Play Games project id
/// (`pgsProjectId`, see MainActivity) — otherwise the game never calls
/// Play Games. Uses only the platform's own account and saved-game slot.
class PlayCloudStore implements CloudStore {
  const PlayCloudStore();

  static const _native = MethodChannel('whisker_tales/play_games');

  /// The one saved-game slot (a-z, 0-9, "_" only).
  static const slot = 'whisker_tales_save';

  @override
  Future<bool> available() async {
    final on = await _native.invokeMethod<bool>('enabled') ?? false;
    if (!on) return false;
    if (await GamesServices.isSignedIn) return true;
    await GamesServices.signIn(); // Play Games v2 signs in without a screen
    return GamesServices.isSignedIn;
  }

  @override
  Future<String?> read() async {
    // "no save yet" must not look like "could not read": list first
    final saved = await SaveGame.getSavedGames(forceRefresh: true);
    if (saved == null) throw StateError('saved games unavailable');
    if (!saved.any((g) => g.name == slot)) return null;
    final data = await SaveGame.loadGame(name: slot);
    if (data == null) throw StateError('saved game unreadable');
    return data;
  }

  @override
  Future<void> write(String data) => SaveGame.saveGame(data: data, name: slot);
}
