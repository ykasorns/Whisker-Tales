import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';
import 'package:wt_core/wt_core_testing.dart';

class _Save extends ModeSaveState {
  _Save(this.best);
  final int best;
}

class _Source implements EncounterSource {
  @override
  Encounter? next(int depth, Random rng) => depth >= 3
      ? null
      : Encounter(type: EncounterType.combat, depth: depth, contentId: 'm');
  @override
  List<EncounterPreview> preview(int depth, int count) => const [];
}

class _Win implements WinCondition {
  @override
  bool isWon(RunResult r) => r.outcome == RunOutcome.won;
}

class _Mode implements GameMode {
  _Mode(this.id, {int order = 1, this.badSave = false, this.rewardFish = 1})
      : manifest = ModeManifest(
            id: id,
            nameTh: 'ท',
            nameEn: 'E',
            icon: 'i',
            order: order,
            enabled: true,
            minAppVersion: '1.0.0');
  @override
  final String id;
  @override
  final ModeManifest manifest;
  final bool badSave;
  final int rewardFish;

  @override
  Widget buildHubCard(BuildContext context, ModeSaveState state) =>
      const SizedBox();
  @override
  RunConfig createRunConfig(ModeSaveState state) => const RunConfig(seed: 7);
  @override
  EncounterSource encounterSource(RunConfig config) => _Source();
  @override
  WinCondition winCondition(RunConfig config) => _Win();
  @override
  RewardResult resolveReward(RunResult result, ModeSaveState state) =>
      RewardResult(reward: RewardBundle({Currency.goldfish: rewardFish}));
  @override
  ModeSaveState decodeSave(Map<String, dynamic> json) {
    if (badSave && json.isNotEmpty) throw const FormatException('bad');
    return _Save(json['best'] as int? ?? 0);
  }

  @override
  Map<String, dynamic> encodeSave(ModeSaveState s) =>
      {'best': (s as _Save).best};
}

Map<String, dynamic> _manifest(String id) => {
      'id': id,
      'name_th': 'ท',
      'name_en': 'E',
      'icon': 'i',
      'order': 1,
      'enabled': true,
      'min_app_version': '1.0.0',
    };

void main() {
  test('modes come sorted by order; enabled ones only for the menu', () {
    final r = ModeRegistry()
      ..register(_Mode('b', order: 2))
      ..register(_Mode('a', order: 1));
    expect(r.modes.map((m) => m.id), ['a', 'b']);
    expect(r.byId('b')!.id, 'b');
    expect(r.byId('zzz'), isNull);
    expect(r.enabledModes, hasLength(2));
  });

  test('a repeated id is refused: ids are save namespaces', () {
    final r = ModeRegistry()..register(_Mode('a'));
    expect(() => r.register(_Mode('a')), throwsStateError);
  });

  test('unlock rules', () {
    const ctx =
        ModeUnlockContext(flags: {'f'}, fishTotal: 50, bossCleared: _isKing);
    expect(isModeUnlocked(null, ctx), isTrue);
    expect(
        isModeUnlocked(
            const UnlockRule(type: UnlockType.flag, value: 'f'), ctx),
        isTrue);
    expect(
        isModeUnlocked(
            const UnlockRule(type: UnlockType.flag, value: 'g'), ctx),
        isFalse);
    expect(
        isModeUnlocked(
            const UnlockRule(type: UnlockType.fishTotal, value: 51), ctx),
        isFalse);
    expect(
        isModeUnlocked(
            const UnlockRule(type: UnlockType.bossCleared, value: 'king'), ctx),
        isTrue);
  });

  group('ModeSaves', () {
    test('keeps what it was given until a mode asks, in any order', () {
      final r = ModeRegistry();
      final saves = ModeSaves(r)
        ..restore({
          'a': {'best': 4},
          'gone': {'x': 1},
        });
      r.register(_Mode('a')); // registered after the save was loaded
      final a = r.byId('a')!;
      expect((saves.stateOf(a) as _Save).best, 4);
      saves.update(a, _Save(9));
      expect(saves.toJson(), {
        'a': {'best': 9},
        'gone': {'x': 1}, // a mode that is not registered keeps its progress
      });
    });

    test('an unreadable mode save starts that mode fresh, nothing else', () {
      final r = ModeRegistry()..register(_Mode('a', badSave: true));
      final saves = ModeSaves(r)
        ..restore({
          'a': {'best': 4},
          'b': {'best': 1},
        });
      expect((saves.stateOf(r.byId('a')!) as _Save).best, 0);
      expect(saves.toJson()['b'], {'best': 1});
    });
  });

  group('conformance', () {
    test('a well-behaved mode passes', () {
      expect(checkModeConformance(_Mode('a'), manifestJson: _manifest('a')),
          isEmpty);
    });
    test('a wrong manifest id and a negative reward are reported', () {
      final problems = checkModeConformance(_Mode('a', rewardFish: -1),
          manifestJson: _manifest('zzz'));
      expect(problems.any((p) => p.contains('manifest id')), isTrue);
      expect(problems.any((p) => p.contains('negative reward')), isTrue);
    });
  });
}

bool _isKing(String id) => id == 'king';
