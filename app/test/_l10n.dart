import 'package:flutter/material.dart';
import 'package:whisker_tales/l10n/strings.dart';

/// A bare app around [home] with the game's strings in [lang] (T-004).
MaterialApp localized(Widget home, {String lang = 'en'}) => MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
