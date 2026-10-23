import 'package:audioplayers/audioplayers.dart';
import 'package:wt_core/wt_core.dart';

/// Real playback for wt_core's [AudioService] (T-024, D-034): two looping
/// music players for crossfades and a small round-robin of low-latency
/// players for effects. Effects never take audio focus, so a "pop" does not
/// pause the music; a phone call or another app still does.
class PlayerAudioOutput implements AudioOutput {
  PlayerAudioOutput() {
    for (final p in _music) {
      p.setReleaseMode(ReleaseMode.loop);
      p.setAudioContext(AudioContext(
          android: const AudioContextAndroid(
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.game)));
    }
    for (final p in _fx) {
      p.setPlayerMode(PlayerMode.lowLatency);
      p.setAudioContext(AudioContext(
          android: const AudioContextAndroid(
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.game,
              audioFocus: AndroidAudioFocus.none)));
    }
  }

  final _music = [AudioPlayer(), AudioPlayer()];
  final _fx = List.generate(4, (_) => AudioPlayer());
  int _next = 0;

  @override
  Future<void> loop(int channel, String asset, double volume) =>
      _music[channel].play(AssetSource(asset), volume: volume);

  @override
  void setVolume(int channel, double volume) =>
      _music[channel].setVolume(volume);

  @override
  void stop(int channel) => _music[channel].stop();

  @override
  Future<void> oneShot(String asset, double volume) {
    final p = _fx[_next];
    _next = (_next + 1) % _fx.length;
    return p.play(AssetSource(asset), volume: volume);
  }

  @override
  void pauseAll() {
    for (final p in _music) {
      if (p.state == PlayerState.playing) p.pause();
    }
  }

  @override
  void resumeAll() {
    for (final p in _music) {
      if (p.state == PlayerState.paused) p.resume();
    }
  }
}
