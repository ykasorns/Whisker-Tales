import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/ui/game_icon.dart';
import 'package:whisker_tales/l10n/strings.dart';

/// A bare app around [home] with the game's strings in [lang] (T-004).
MaterialApp localized(Widget home, {String lang = 'en'}) => MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

/// Finds a label drawn by [IconText], which shows its emoji as painted icons
/// (D-037). Matches the IconText itself, so it works with or without the
/// icon registry loaded.
Finder findLabel(String data) =>
    find.byWidgetPredicate((w) => w is IconText && w.data == data,
        description: 'label "$data"');
