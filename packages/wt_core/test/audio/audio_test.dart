import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

/// Records what the sound device was asked to do.
class RecOut implements AudioOutput {
  final vol = <int, double>{};
  final playing = <int, String>{};
  final shots = <String>[];
  final log = <String>[];
  bool paused = false;

  @override
  Future<void> loop(int channel, String asset, double volume) async {
    playing[channel] = asset;
    vol[channel] = volume;
    log.add('loop $channel $asset');
  }

  @override
  void setVolume(int channel, double volume) => vol[channel] = volume;

  @override
  void stop(int channel) {
    playing.remove(channel);
    vol.remove(channel);
    log.add('stop $channel');
  }

  @override
  Future<void> oneShot(String asset, double volume) async => shots.add(asset);
  @override
  void pauseAll() => paused = true;
  @override
  void resumeAll() => paused = false;
}

/// T-024 AC: scene changes crossfade without a jump; mute works at once,
/// everywhere; both switches are saved.
void main() {
  final rules = AudioRules.fromJson(jsonDecode(
          File('../../design/data/audio.json').readAsStringSync())
      as Map<String, dynamic>);
  late RecOut out;
  late AudioService audio;
  var now = 0;
  setUp(() {
    out = RecOut();
    now = 0;
    audio = AudioService(rules, out, nowMs: () => now);
  });

  test('data: every file exists in the app bundle', () {
    for (final f in [...rules.bgm.values, ...rules.sfx.values]) {
      expect(File('../../app/assets/$f').existsSync(), isTrue, reason: f);
    }
    expect(rules.bgm.keys, containsAll(['farm', 'boss']));
  });

  test('switching music crossfades smoothly: no jump, no gap', () async {
    await audio.playBgm('farm');
    expect(out.vol[0], rules.bgmVolume);
    await audio.playBgm('boss');
    expect(out.playing[1], rules.bgm['boss']);
    expect(out.vol[1], 0); // the new one starts silent …
    expect(out.playing[0], rules.bgm['farm']); // … the old keeps going
    var lastIn = 0.0, lastOut = rules.bgmVolume;
    const step = 30; // ~a frame at 30 fps
    for (var t = 0; t < rules.crossfadeMs; t += step) {
      audio.tick(step);
      final vIn = out.vol[1]!, vOut = out.vol[0] ?? 0;
      expect(vIn, greaterThanOrEqualTo(lastIn));
      expect(vOut, lessThanOrEqualTo(lastOut));
      // no step bigger than this frame's share of the fade
      expect(vIn - lastIn,
          lessThanOrEqualTo(rules.bgmVolume * step / rules.crossfadeMs + 1e-9));
      lastIn = vIn;
      lastOut = vOut;
    }
    audio.tick(step);
    expect(out.vol[1], rules.bgmVolume);
    expect(out.playing.containsKey(0), isFalse); // old track stopped at the end
    await audio.playBgm('boss'); // same track: nothing restarts
    expect(out.log.where((l) => l.startsWith('loop')).length, 2);
  });

  test('switching again mid-fade never leaves two old tracks running',
      () async {
    await audio.playBgm('farm');
    await audio.playBgm('boss');
    audio.tick(rules.crossfadeMs ~/ 2);
    final half = out.vol[1]!;
    await audio.playBgm('farm');
    expect(out.playing.length, 2);
    audio.tick(1);
    expect(out.vol[1]!, lessThanOrEqualTo(half)); // fades out from where it was
    audio.tick(rules.crossfadeMs);
    expect(out.playing.values.single, rules.bgm['farm']);
  });

  test('mute is immediate everywhere; unmute brings back the right track',
      () async {
    await audio.playBgm('farm');
    await audio.playBgm('boss');
    audio.setBgmEnabled(false);
    expect(out.playing, isEmpty);
    await audio.playBgm('farm'); // the scene changes while muted
    expect(out.playing, isEmpty);
    audio.setBgmEnabled(true);
    expect(out.playing.values.single, rules.bgm['farm']);

    audio.setSfxEnabled(false);
    await audio.playSfx('hit');
    expect(out.shots, isEmpty);
    audio.setSfxEnabled(true);
    await audio.playSfx('hit');
    expect(out.shots, [rules.sfx['hit']]);
  });

  test('the same effect cannot machine-gun; different ones can overlap',
      () async {
    await audio.playSfx('hit');
    await audio.playSfx('hit');
    await audio.playSfx('crit');
    expect(out.shots.length, 2);
    now += rules.sfxMinGapMs;
    await audio.playSfx('hit');
    expect(out.shots.length, 3);
    await audio.playSfx('no_such_sound'); // unknown ids are ignored
    expect(out.shots.length, 3);
  });

  test('in the background: everything pauses, effects stay quiet', () async {
    await audio.playBgm('farm');
    audio.pause();
    expect(out.paused, isTrue);
    await audio.playSfx('coin');
    expect(out.shots, isEmpty);
    audio.resume();
    expect(out.paused, isFalse);
  });

  test('bad data names the field', () {
    expect(
        () => AudioRules.fromJson({
              'bgm': {'farm': 'x.mp3'},
              'sfx': {'hit': 'a.ogg'},
              'crossfade_ms': 1,
              'sfx_min_gap_ms': 1,
              'bgm_volume': 1,
              'sfx_volume': 1
            }),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('bgm'))));
  });

  test('both switches are saved in settings and come back', () async {
    final content = await ContentRepository(_Disk()).loadAll();
    ProviderContainer make(SaveService saves) =>
        ProviderContainer(overrides: [
          ...content.overrides,
          saveServiceProvider.overrideWithValue(saves),
        ]);
    final saves = SaveService(MemorySaveStore());
    final a = make(saves);
    a.read(audioServiceProvider)
      ..setBgmEnabled(false)
      ..setSfxEnabled(false);
    await a.read(gameSaverProvider).save();
    final b = make(saves);
    await b.read(gameSaverProvider).load();
    expect(b.read(audioServiceProvider).bgmEnabled, isFalse);
    expect(b.read(audioServiceProvider).sfxEnabled, isFalse);
  });
}

class _Disk implements ContentSource {
  @override
  Future<String> read(String path) async =>
      File('../../$path').readAsStringSync();
}
