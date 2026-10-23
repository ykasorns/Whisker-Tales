import '../core/contracts/services.dart';

/// `design/data/audio.json` (T-024, D-034).
class AudioRules {
  const AudioRules({
    required this.bgm,
    required this.sfx,
    required this.crossfadeMs,
    required this.bgmVolume,
    required this.sfxVolume,
    required this.sfxMinGapMs,
  });

  /// No files: every call is a no-op (before content loads, in tests).
  static const none = AudioRules(
      bgm: {},
      sfx: {},
      crossfadeMs: 0,
      bgmVolume: 0,
      sfxVolume: 0,
      sfxMinGapMs: 0);

  /// id → asset path under `assets/`.
  final Map<String, String> bgm, sfx;
  final int crossfadeMs, sfxMinGapMs;
  final double bgmVolume, sfxVolume;

  factory AudioRules.fromJson(Map<String, dynamic> j) {
    Map<String, String> files(String k) {
      final m = j[k];
      if (m is! Map<String, dynamic> ||
          m.isEmpty ||
          m.values.any((v) => v is! String || !v.endsWith('.ogg'))) {
        throw FormatException('audio: "$k" must map ids to .ogg files');
      }
      return Map.unmodifiable(m.cast<String, String>());
    }

    double vol(String k) {
      final v = j[k];
      if (v is! num || v < 0 || v > 1) {
        throw FormatException('audio: "$k" must be 0–1');
      }
      return v.toDouble();
    }

    int ms(String k) {
      final v = j[k];
      if (v is! int || v < 0) throw FormatException('audio: "$k" must be ms');
      return v;
    }

    return AudioRules(
      bgm: files('bgm'),
      sfx: files('sfx'),
      crossfadeMs: ms('crossfade_ms'),
      sfxMinGapMs: ms('sfx_min_gap_ms'),
      bgmVolume: vol('bgm_volume'),
      sfxVolume: vol('sfx_volume'),
    );
  }
}

/// The sound device: two looping music channels (0 and 1, for crossfades)
/// and one-shot effects. The app plays real files; tests record calls.
abstract class AudioOutput {
  Future<void> loop(int channel, String asset, double volume);
  void setVolume(int channel, double volume);
  void stop(int channel);
  Future<void> oneShot(String asset, double volume);
  void pauseAll();
  void resumeAll();
}

/// Silent output (tests, and before the app wires a real one).
class SilentAudioOutput implements AudioOutput {
  @override
  Future<void> loop(int channel, String asset, double volume) async {}
  @override
  void setVolume(int channel, double volume) {}
  @override
  void stop(int channel) {}
  @override
  Future<void> oneShot(String asset, double volume) async {}
  @override
  void pauseAll() {}
  @override
  void resumeAll() {}
}

/// Music and sound effects (GDD v0.3 §11, T-024). Switching music fades the
/// old track out while the new one fades in ([tick] moves the fade, so it
/// never jumps); muting music or effects is immediate everywhere; both
/// switches are saved in `settings.bgm` / `settings.sfx`.
class AudioService implements IAudioService {
  AudioService(this.rules, this.out, {int Function()? nowMs})
      : _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AudioRules rules;
  final AudioOutput out;
  final int Function() _nowMs;

  bool _bgmOn = true, _sfxOn = true, _paused = false;
  bool get bgmEnabled => _bgmOn;
  bool get sfxEnabled => _sfxOn;

  /// The track that should be playing (kept while music is off, so turning
  /// it back on resumes the right one).
  String? get currentBgm => _current;
  String? _current;

  int _active = 0; // channel of [_current]
  bool _playing = false; // something is on [_active]
  int? _fadeFrom; // channel fading out, null when no fade runs
  double _fromStart = 0; // its volume when the fade began
  int _fadeMs = 0;
  final _lastSfx = <String, int>{};

  /// Starts [id] with a crossfade; the same track again does nothing.
  @override
  Future<void> playBgm(String id) async {
    final asset = rules.bgm[id];
    if (asset == null || id == _current) return;
    _current = id;
    if (!_bgmOn) return;
    if (!_playing) {
      _playing = true;
      await out.loop(_active, asset, rules.bgmVolume);
      return;
    }
    // a fade already running: its outgoing track goes now, the incoming
    // one becomes the outgoing track from where it got to
    if (_fadeFrom != null) {
      out.stop(_fadeFrom!);
      _fromStart = _volumeIn();
    } else {
      _fromStart = rules.bgmVolume;
    }
    _fadeFrom = _active;
    _active = 1 - _active;
    _fadeMs = 0;
    await out.loop(_active, asset, 0);
    if (rules.crossfadeMs == 0) tick(0);
  }

  double _volumeIn() => rules.crossfadeMs == 0
      ? rules.bgmVolume
      : rules.bgmVolume * (_fadeMs / rules.crossfadeMs).clamp(0.0, 1.0);

  /// Moves a running crossfade on by [ms] of real time.
  void tick(int ms) {
    final from = _fadeFrom;
    if (from == null) return;
    _fadeMs += ms;
    final t = rules.crossfadeMs == 0
        ? 1.0
        : (_fadeMs / rules.crossfadeMs).clamp(0.0, 1.0);
    out.setVolume(_active, rules.bgmVolume * t);
    out.setVolume(from, _fromStart * (1 - t));
    if (t >= 1) {
      out.stop(from);
      _fadeFrom = null;
    }
  }

  /// Plays effect [id] unless effects are off or it just played.
  @override
  Future<void> playSfx(String id) async {
    final asset = rules.sfx[id];
    if (!_sfxOn || _paused || asset == null) return;
    final now = _nowMs();
    final last = _lastSfx[id];
    if (last != null && now - last < rules.sfxMinGapMs) return;
    _lastSfx[id] = now;
    await out.oneShot(asset, rules.sfxVolume);
  }

  @override
  void setBgmEnabled(bool enabled) {
    if (enabled == _bgmOn) return;
    _bgmOn = enabled;
    if (!enabled) {
      out.stop(0);
      out.stop(1);
      _playing = false;
      _fadeFrom = null;
    } else if (_current case final id?) {
      _playing = true;
      out.loop(_active, rules.bgm[id]!, rules.bgmVolume);
    }
  }

  @override
  void setSfxEnabled(bool enabled) => _sfxOn = enabled;

  /// App went to the background / came back.
  void pause() {
    _paused = true;
    out.pauseAll();
  }

  void resume() {
    _paused = false;
    out.resumeAll();
  }
}
