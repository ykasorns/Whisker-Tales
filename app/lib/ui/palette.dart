import 'package:flutter/material.dart';

/// Colored-pencil storybook palette (ART_PROMPT_BIBLE; same as the web
/// prototype).
abstract final class Palette {
  static const ink = Color(0xFF33291F);
  static const inkSoft = Color(0xFF6B5D4E);
  static const paper = Color(0xFFFFFBF2);
  static const sheet = Color(0xFFF5EFE3);
  static const storyPaper = Color(0xFFF2E2C5);
  static const storyEdge = Color(0xFFB78755);
  static const parchment = Color(0xFFFFF2D2);
  static const parchmentDeep = Color(0xFFF3D79E);
  static const wood = Color(0xFF8A552D);
  static const woodDark = Color(0xFF57351F);
  static const mochi = Color(0xFFF6A83C);
  static const coral = Color(0xFFEE6352);
  static const sun = Color(0xFFF9D64E);
  static const lime = Color(0xFF8CC152);
  static const teal = Color(0xFF3FA7B8);
  static const plum = Color(0xFF7A5E8C);
  static const grades = [
    Color(0xFFB9AE9C),
    Color(0xFF8CC152),
    Color(0xFF3FA7B8),
    Color(0xFF7A5E8C),
    Color(0xFFF9D64E),
    Color(0xFFEE6352),
  ];
}

BorderRadius _paperCorners(double radius) => BorderRadius.only(
      topLeft: Radius.circular(radius * .58),
      topRight: Radius.circular(radius),
      bottomRight: Radius.circular(radius * .62),
      bottomLeft: Radius.circular(radius * .88),
    );

/// A tappable paper surface separated by colour and a soft shadow. The
/// [accent] colour appears as a tint and shadow; no edge is
/// drawn (D-045).
BoxDecoration inkBox(
    {Color fill = Palette.paper,
    double radius = 14,
    Color accent = Palette.ink,
    double elevation = 2.5}) {
  final top = Color.lerp(fill, Colors.white, 0.22)!;
  final bottom = Color.lerp(fill, accent, 0.16)!;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [top, fill, bottom],
      stops: const [0, 0.58, 1],
    ),
    borderRadius: _paperCorners(radius),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: 0.22),
        blurRadius: 1.5 + elevation,
        offset: Offset(1, 2 + elevation * 0.55),
      ),
    ],
  );
}

/// Quiet paper shared by the home controls and the Cat collection pages.
class StorybookPaper extends StatelessWidget {
  const StorybookPaper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Palette.storyPaper,
          image: DecorationImage(
            image: AssetImage('assets/game/ui/ui_storybook_paper.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: child,
      );
}

/// Light paper slip. Accent colour appears in the paper tint and shadow,
/// keeping neighbouring menu items distinct without a frame.
BoxDecoration storybookCard({
  Color fill = Palette.parchment,
  Color accent = Palette.storyEdge,
  double radius = 14,
}) {
  final top = Color.lerp(fill, Colors.white, 0.18)!;
  final bottom = Color.lerp(fill, accent, 0.14)!;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [top, fill, bottom],
    ),
    borderRadius: _paperCorners(radius),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: 0.16),
        blurRadius: 4,
        offset: const Offset(1.5, 3),
      ),
    ],
  );
}

/// A louder, tactile surface reserved for actions. Panels stay quiet while
/// buttons get a coloured face and a darker paper edge, so the hierarchy is
/// visible without drawing a black outline around every control.
BoxDecoration storybookButton({
  Color fill = Palette.sun,
  Color accent = Palette.coral,
  double radius = 12,
  bool enabled = true,
}) {
  final face = enabled ? fill : Palette.sheet;
  final edge = enabled ? accent : Palette.inkSoft;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(face, Colors.white, .20)!,
        face,
        Color.lerp(face, edge, .20)!,
      ],
      stops: const [0, .68, 1],
    ),
    borderRadius: _paperCorners(radius),
    boxShadow: [
      BoxShadow(
        color: edge.withValues(alpha: enabled ? .32 : .12),
        blurRadius: 2,
        offset: const Offset(1, 4),
      ),
    ],
  );
}

/// Compact pinned label used for currencies and small live counters.
class StoryTag extends StatelessWidget {
  const StoryTag({
    super.key,
    required this.child,
    this.color = Palette.parchment,
    this.accent = Palette.storyEdge,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  final Widget child;
  final Color color;
  final Color accent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: storybookCard(fill: color, accent: accent, radius: 8),
        child: child,
      );
}
