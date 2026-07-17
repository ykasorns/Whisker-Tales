/// Fixed split between the Flame [GameWidget] and the Flutter UI panel,
/// measured from the device safe area (GAME_CONTRACT.md §5).
class AppLayout {
  static const double gameViewportRatio = 0.60;
  static const double uiPanelRatio = 1 - gameViewportRatio;
}
