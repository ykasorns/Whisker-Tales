import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

void main() {
  test('game viewport ratio is 0.60 per GAME_CONTRACT §5', () {
    expect(AppLayout.gameViewportRatio, 0.60);
  });

  test('game viewport and ui panel ratios fill the safe area', () {
    expect(AppLayout.gameViewportRatio + AppLayout.uiPanelRatio, 1.0);
  });
}
