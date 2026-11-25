import 'package:flutter/material.dart';

import 'palette.dart';

/// Keeps the game in an upright phone shape on wide screens (web on a
/// desktop or a landscape tablet) until the wide layout exists. On a phone
/// held upright it changes nothing.
class PortraitFrame extends StatelessWidget {
  const PortraitFrame({super.key, required this.child});

  final Widget child;

  /// Width / height of the frame: a tall phone.
  static const aspect = 9 / 19.5;

  /// Narrower than this (width / height) already fits the game.
  static const fitsAt = 0.68;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    if (size.height <= 0 || size.width / size.height <= fitsAt) return child;
    final h = size.height - mq.padding.vertical;
    final w = h * aspect;
    return ColoredBox(
      color: Palette.ink,
      child: Center(
        child: SizedBox(
          width: w,
          height: h,
          child: ClipRect(
            child: MediaQuery(
              data: mq.copyWith(
                  size: Size(w, h),
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
