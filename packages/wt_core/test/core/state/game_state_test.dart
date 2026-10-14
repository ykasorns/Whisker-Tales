import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

void main() {
  group('RunStateMachine', () {
    test('walks the full walk → encounter → resolve → walk cycle', () {
      final m = RunStateMachine();
      expect(m.state, RunState.initial);

      m.start();
      expect(m.state, const RunState(phase: RunPhase.walking));

      for (var depth = 0; depth < 3; depth++) {
        m.reachEncounter();
        expect(m.state, RunState(phase: RunPhase.encounter, depth: depth));
        m.resolve();
        expect(m.state, RunState(phase: RunPhase.resolving, depth: depth));
        m.walkOn();
        expect(m.state, RunState(phase: RunPhase.walking, depth: depth + 1));
      }

      m.reachEncounter();
      m.end(RunOutcome.won);
      expect(
          m.state,
          const RunState(
              phase: RunPhase.ended, depth: 3, outcome: RunOutcome.won));
    });

    test('a new run can start after one ends', () {
      final m = RunStateMachine()
        ..start()
        ..end(RunOutcome.died);
      m.start();
      expect(m.state, const RunState(phase: RunPhase.walking));
    });

    test('the run can end from every active phase', () {
      for (final reach in [0, 1, 2]) {
        final m = RunStateMachine()..start();
        if (reach >= 1) m.reachEncounter();
        if (reach >= 2) m.resolve();
        m.end(RunOutcome.abandoned);
        expect(m.state.phase, RunPhase.ended);
      }
    });

    test('illegal transitions throw and leave the state unchanged', () {
      final m = RunStateMachine();
      expect(m.reachEncounter, throwsStateError);
      expect(() => m.end(RunOutcome.won), throwsStateError);
      m.start();
      expect(m.start, throwsStateError);
      expect(m.resolve, throwsStateError);
      expect(m.walkOn, throwsStateError);
      expect(m.state, const RunState(phase: RunPhase.walking));
    });
  });

  group('GameStateMachine', () {
    test('boot → age gate → hub → run → hub', () {
      final m = GameStateMachine();
      for (final s in [
        GameState.ageGate,
        GameState.hub,
        GameState.run,
        GameState.hub
      ]) {
        m.goTo(s);
        expect(m.state, s);
      }
    });

    test('returning players skip the age gate', () {
      final m = GameStateMachine()..goTo(GameState.hub);
      expect(m.state, GameState.hub);
    });

    test('illegal changes throw', () {
      final m = GameStateMachine();
      expect(() => m.goTo(GameState.run), throwsStateError);
      m.goTo(GameState.hub);
      expect(() => m.goTo(GameState.ageGate), throwsStateError);
      expect(() => m.goTo(GameState.boot), throwsStateError);
    });
  });

  test('providers expose both machines', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(gameStateProvider), GameState.boot);
    c.read(runStateProvider.notifier).start();
    expect(c.read(runStateProvider).phase, RunPhase.walking);
  });
}
