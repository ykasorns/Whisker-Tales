import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th')
  ];

  /// No description provided for @navCharacter.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get navCharacter;

  /// No description provided for @navDungeon.
  ///
  /// In en, this message translates to:
  /// **'Dungeon'**
  String get navDungeon;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @navShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get navShop;

  /// No description provided for @autoCraft.
  ///
  /// In en, this message translates to:
  /// **'Auto-knit'**
  String get autoCraft;

  /// No description provided for @betterStash.
  ///
  /// In en, this message translates to:
  /// **'Better: keep for me'**
  String get betterStash;

  /// No description provided for @betterEquip.
  ///
  /// In en, this message translates to:
  /// **'Better: wear now'**
  String get betterEquip;

  /// No description provided for @knit.
  ///
  /// In en, this message translates to:
  /// **'Knit'**
  String get knit;

  /// No description provided for @noYarn.
  ///
  /// In en, this message translates to:
  /// **'Out of yarn — fight for more'**
  String get noYarn;

  /// No description provided for @yarnLeft.
  ///
  /// In en, this message translates to:
  /// **'Tap the yarn · {n} left'**
  String yarnLeft(int n);

  /// No description provided for @chapterPage.
  ///
  /// In en, this message translates to:
  /// **'Ch {ch} · Page {p}/10'**
  String chapterPage(int ch, int p);

  /// No description provided for @farm.
  ///
  /// In en, this message translates to:
  /// **'Farm {done}/{all}'**
  String farm(int done, int all);

  /// No description provided for @tapForBoss.
  ///
  /// In en, this message translates to:
  /// **'Tap to fight the boss!'**
  String get tapForBoss;

  /// No description provided for @fightingBoss.
  ///
  /// In en, this message translates to:
  /// **'Boss fight'**
  String get fightingBoss;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'AUTO'**
  String get auto;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get off;

  /// No description provided for @unlockAt.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String unlockAt(int page);

  /// No description provided for @pickSlot.
  ///
  /// In en, this message translates to:
  /// **'Pick a slot to knit'**
  String get pickSlot;

  /// No description provided for @worn.
  ///
  /// In en, this message translates to:
  /// **'Wearing'**
  String get worn;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newItem;

  /// No description provided for @equip.
  ///
  /// In en, this message translates to:
  /// **'Wear'**
  String get equip;

  /// No description provided for @recycle.
  ///
  /// In en, this message translates to:
  /// **'Recycle +{fish}🐟'**
  String recycle(int fish);

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @dungeonSoon.
  ///
  /// In en, this message translates to:
  /// **'Dungeons open in the next version'**
  String get dungeonSoon;

  /// No description provided for @tabCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get tabCat;

  /// No description provided for @tabWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get tabWardrobe;

  /// No description provided for @tabPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get tabPets;

  /// No description provided for @tabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get tabLibrary;

  /// No description provided for @classPick.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classPick;

  /// No description provided for @classAt.
  ///
  /// In en, this message translates to:
  /// **'Pick a class at Lv.{lv}'**
  String classAt(int lv);

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills (auto)'**
  String get skills;

  /// No description provided for @dailyGift.
  ///
  /// In en, this message translates to:
  /// **'Daily gift'**
  String get dailyGift;

  /// No description provided for @yarnBundle.
  ///
  /// In en, this message translates to:
  /// **'Yarn bundle'**
  String get yarnBundle;

  /// No description provided for @adsLeft.
  ///
  /// In en, this message translates to:
  /// **'{n} left today'**
  String adsLeft(int n);

  /// No description provided for @watch.
  ///
  /// In en, this message translates to:
  /// **'Watch 📺'**
  String get watch;

  /// No description provided for @supporterPack.
  ///
  /// In en, this message translates to:
  /// **'Supporter Pack'**
  String get supporterPack;

  /// No description provided for @supporterDesc.
  ///
  /// In en, this message translates to:
  /// **'Hides every ad button · no power'**
  String get supporterDesc;

  /// No description provided for @askParent.
  ///
  /// In en, this message translates to:
  /// **'Ask a grown-up to buy'**
  String get askParent;

  /// No description provided for @gateTitle.
  ///
  /// In en, this message translates to:
  /// **'For grown-ups 👨‍👩‍👧'**
  String get gateTitle;

  /// No description provided for @gateAsk.
  ///
  /// In en, this message translates to:
  /// **'What is {q}?'**
  String gateAsk(String q);

  /// No description provided for @gateWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite — here is a new one'**
  String get gateWrong;

  /// No description provided for @gateExpired.
  ///
  /// In en, this message translates to:
  /// **'Time ran out — please ask a grown-up again'**
  String get gateExpired;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @shopClosed.
  ///
  /// In en, this message translates to:
  /// **'The shop is closed right now'**
  String get shopClosed;

  /// No description provided for @owned.
  ///
  /// In en, this message translates to:
  /// **'Owned ✓'**
  String get owned;

  /// No description provided for @buying.
  ///
  /// In en, this message translates to:
  /// **'Opening the payment screen…'**
  String get buying;

  /// No description provided for @bought.
  ///
  /// In en, this message translates to:
  /// **'Got it 🎉 Thank you for your support!'**
  String get bought;

  /// No description provided for @payPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the payment — it arrives once paid'**
  String get payPending;

  /// No description provided for @buyFailed.
  ///
  /// In en, this message translates to:
  /// **'That did not work — please try again'**
  String get buyFailed;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring earlier purchases…'**
  String get restoring;

  /// No description provided for @gradeNames.
  ///
  /// In en, this message translates to:
  /// **'White,Green,Blue,Purple,Gold,Rainbow'**
  String get gradeNames;

  /// No description provided for @lockedLook.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get lockedLook;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @awayFarmed.
  ///
  /// In en, this message translates to:
  /// **'Mochi farmed for {min} minutes while you were away'**
  String awayFarmed(int min);

  /// No description provided for @claim.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get claim;

  /// No description provided for @hatch.
  ///
  /// In en, this message translates to:
  /// **'Hatch'**
  String get hatch;

  /// No description provided for @useEgg.
  ///
  /// In en, this message translates to:
  /// **'🥚 Egg ({n})'**
  String useEgg(int n);

  /// No description provided for @adFree.
  ///
  /// In en, this message translates to:
  /// **'📺 Free · {n} left'**
  String adFree(int n);

  /// No description provided for @fishHatch.
  ///
  /// In en, this message translates to:
  /// **'🐟 {cost} · {n} left'**
  String fishHatch(int cost, int n);

  /// No description provided for @odds.
  ///
  /// In en, this message translates to:
  /// **'Common {c}% · Rare {r}% · Legend {l}% · Legend guaranteed in {pity}'**
  String odds(int c, int r, int l, int pity);

  /// No description provided for @askAge.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get askAge;

  /// No description provided for @changeAge.
  ///
  /// In en, this message translates to:
  /// **'👨‍👩‍👧 Change the player\'s age (grown-ups)'**
  String get changeAge;

  /// No description provided for @classOutfits.
  ///
  /// In en, this message translates to:
  /// **'Class outfits (Mochi wears the chosen class\'s outfit)'**
  String get classOutfits;

  /// No description provided for @looksFound.
  ///
  /// In en, this message translates to:
  /// **'Looks knitted so far {n}/{all}'**
  String looksFound(int n, int all);

  /// No description provided for @saveOlder.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the latest save 😿 so we went on from the one before (the old save is kept)'**
  String get saveOlder;

  /// No description provided for @saveNew.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the save 😿 so a new game started (the old save is kept)'**
  String get saveNew;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Owl Library'**
  String get libraryTitle;

  /// No description provided for @statNode.
  ///
  /// In en, this message translates to:
  /// **'{stat} +{per}%/level (now +{now}%)'**
  String statNode(String stat, String per, String now);

  /// No description provided for @offlineNode.
  ///
  /// In en, this message translates to:
  /// **'Collect for longer while away (now {cap} h)'**
  String offlineNode(String cap);

  /// No description provided for @queueNode.
  ///
  /// In en, this message translates to:
  /// **'Research 2 things at once'**
  String get queueNode;

  /// No description provided for @adSpeedUp.
  ///
  /// In en, this message translates to:
  /// **'📺 Watch an ad: {min}+ min faster · {left} left'**
  String adSpeedUp(int min, int left);

  /// No description provided for @notifyResearch.
  ///
  /// In en, this message translates to:
  /// **'🔔 Tell me when research is done'**
  String get notifyResearch;

  /// No description provided for @deskFree.
  ///
  /// In en, this message translates to:
  /// **'Desk {i} is free — pick a topic below'**
  String deskFree(int i);

  /// No description provided for @maxed.
  ///
  /// In en, this message translates to:
  /// **'Maxed'**
  String get maxed;

  /// No description provided for @researching.
  ///
  /// In en, this message translates to:
  /// **'Researching…'**
  String get researching;

  /// No description provided for @queueFull.
  ///
  /// In en, this message translates to:
  /// **'Desks full'**
  String get queueFull;

  /// No description provided for @researchDone.
  ///
  /// In en, this message translates to:
  /// **'🦉 Research done: {name} Lv.{lv}'**
  String researchDone(String name, int lv);

  /// No description provided for @newPet.
  ///
  /// In en, this message translates to:
  /// **'New friend!'**
  String get newPet;

  /// No description provided for @starUp.
  ///
  /// In en, this message translates to:
  /// **'Star up!'**
  String get starUp;

  /// No description provided for @treats.
  ///
  /// In en, this message translates to:
  /// **'Got treats 🍪 {n}'**
  String treats(int n);

  /// No description provided for @deploySlots.
  ///
  /// In en, this message translates to:
  /// **'In battle {used}/{all}'**
  String deploySlots(int used, int all);

  /// No description provided for @deployHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a friend to send it to battle / rest'**
  String get deployHint;

  /// No description provided for @yay.
  ///
  /// In en, this message translates to:
  /// **'Yay!'**
  String get yay;

  /// No description provided for @statAtk.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get statAtk;

  /// No description provided for @statHp.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get statHp;

  /// No description provided for @statDef.
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get statDef;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'🎵 Music'**
  String get music;

  /// No description provided for @sounds.
  ///
  /// In en, this message translates to:
  /// **'🔊 Sounds'**
  String get sounds;

  /// No description provided for @shortHp.
  ///
  /// In en, this message translates to:
  /// **'HP'**
  String get shortHp;

  /// No description provided for @shortAtk.
  ///
  /// In en, this message translates to:
  /// **'ATK'**
  String get shortAtk;

  /// No description provided for @shortDef.
  ///
  /// In en, this message translates to:
  /// **'DEF'**
  String get shortDef;

  /// No description provided for @shortEvade.
  ///
  /// In en, this message translates to:
  /// **'Dodge'**
  String get shortEvade;

  /// No description provided for @shortCrit.
  ///
  /// In en, this message translates to:
  /// **'Crit'**
  String get shortCrit;

  /// No description provided for @shortSkill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get shortSkill;

  /// No description provided for @shortPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get shortPower;

  /// No description provided for @curFish.
  ///
  /// In en, this message translates to:
  /// **'Goldfish'**
  String get curFish;

  /// No description provided for @curYarn.
  ///
  /// In en, this message translates to:
  /// **'Yarn'**
  String get curYarn;

  /// No description provided for @curEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get curEggs;

  /// No description provided for @pityLabel.
  ///
  /// In en, this message translates to:
  /// **'Guarantee in {n}'**
  String pityLabel(int n);

  /// Shown in the other language: the one it switches to
  ///
  /// In en, this message translates to:
  /// **'🌐 ภาษาไทย'**
  String get switchLanguage;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Lv.{lv}'**
  String level(int lv);

  /// No description provided for @catTitle.
  ///
  /// In en, this message translates to:
  /// **'Mochi · {cls}'**
  String catTitle(String cls);

  /// Class id → its name
  ///
  /// In en, this message translates to:
  /// **'{cls, select, novice{Novice} warrior{Warrior} rogue{Rogue} archer{Archer} mage{Mage} other{{cls}}}'**
  String className(String cls);

  /// No description provided for @cooldownSeconds.
  ///
  /// In en, this message translates to:
  /// **'Cooldown {sec} s'**
  String cooldownSeconds(String sec);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
