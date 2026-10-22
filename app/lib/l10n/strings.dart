import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// UI strings live in `app_th.arb` / `app_en.arb` (T-004, D-028) and come
/// through `AppLocalizations.of(context)`. These helpers cover what an arb
/// message cannot. Content names (pets, skills, research …) come from
/// `design/data/*.json` `name_th` / `name_en`, chosen with [lang].
extension L10n on AppLocalizations {
  /// `th` or `en`.
  String get lang => localeName.startsWith('en') ? 'en' : 'th';

  /// Main stat name for `atk` / `hp` / `def`.
  String statName(String stat) => switch (stat) {
        'atk' => statAtk,
        'hp' => statHp,
        _ => statDef,
      };
}
