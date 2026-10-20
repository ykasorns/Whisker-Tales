import 'package:flutter/material.dart';

/// Colored-pencil storybook palette (ART_PROMPT_BIBLE; same as the web
/// prototype).
abstract final class Palette {
  static const ink = Color(0xFF33291F);
  static const inkSoft = Color(0xFF6B5D4E);
  static const paper = Color(0xFFFFFBF2);
  static const sheet = Color(0xFFF5EFE3);
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

/// Sketchy card: paper fill, ink border, hard drop shadow.
BoxDecoration inkBox(
        {Color fill = Palette.paper,
        double radius = 14,
        Color border = Palette.ink,
        double width = 2.5}) =>
    BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border, width: width),
      boxShadow: const [BoxShadow(color: Palette.ink, offset: Offset(0, 3))],
    );
