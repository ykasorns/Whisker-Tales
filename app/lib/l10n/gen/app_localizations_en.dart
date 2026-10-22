// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navCharacter => 'Cat';

  @override
  String get navDungeon => 'Dungeon';

  @override
  String get navHome => 'Home';

  @override
  String get navEvents => 'Events';

  @override
  String get navShop => 'Shop';

  @override
  String get autoCraft => 'Auto-knit';

  @override
  String get betterStash => 'Better: keep for me';

  @override
  String get betterEquip => 'Better: wear now';

  @override
  String get knit => 'Knit';

  @override
  String get noYarn => 'Out of yarn — fight for more';

  @override
  String yarnLeft(int n) {
    return 'Tap the yarn · $n left';
  }

  @override
  String chapterPage(int ch, int p) {
    return 'Ch $ch · Page $p/10';
  }

  @override
  String farm(int done, int all) {
    return 'Farm $done/$all';
  }

  @override
  String get tapForBoss => 'Tap to fight the boss!';

  @override
  String get fightingBoss => 'Boss fight';

  @override
  String get auto => 'AUTO';

  @override
  String get on => 'on';

  @override
  String get off => 'off';

  @override
  String unlockAt(int page) {
    return 'Page $page';
  }

  @override
  String get pickSlot => 'Pick a slot to knit';

  @override
  String get worn => 'Wearing';

  @override
  String get newItem => 'New';

  @override
  String get equip => 'Wear';

  @override
  String recycle(int fish) {
    return 'Recycle +$fish🐟';
  }

  @override
  String get empty => 'Empty';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get dungeonSoon => 'Dungeons open in the next version';

  @override
  String get tabCat => 'Cat';

  @override
  String get tabWardrobe => 'Collection';

  @override
  String get tabPets => 'Pets';

  @override
  String get tabLibrary => 'Library';

  @override
  String get classPick => 'Class';

  @override
  String classAt(int lv) {
    return 'Pick a class at Lv.$lv';
  }

  @override
  String get skills => 'Skills (auto)';

  @override
  String get dailyGift => 'Daily gift';

  @override
  String get yarnBundle => 'Yarn bundle';

  @override
  String adsLeft(int n) {
    return '$n left today';
  }

  @override
  String get watch => 'Watch 📺';

  @override
  String get supporterPack => 'Supporter Pack';

  @override
  String get supporterDesc => 'Hides every ad button · no power';

  @override
  String get askParent => 'Ask a grown-up to buy';

  @override
  String get gateTitle => 'For grown-ups 👨‍👩‍👧';

  @override
  String gateAsk(String q) {
    return 'What is $q?';
  }

  @override
  String get gateWrong => 'Not quite — here is a new one';

  @override
  String get gateExpired => 'Time ran out — please ask a grown-up again';

  @override
  String get cancel => 'Cancel';

  @override
  String get shopClosed => 'The shop is closed right now';

  @override
  String get owned => 'Owned ✓';

  @override
  String get buying => 'Opening the payment screen…';

  @override
  String get bought => 'Got it 🎉 Thank you for your support!';

  @override
  String get payPending => 'Waiting for the payment — it arrives once paid';

  @override
  String get buyFailed => 'That did not work — please try again';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get restoring => 'Restoring earlier purchases…';

  @override
  String get gradeNames => 'White,Green,Blue,Purple,Gold,Rainbow';

  @override
  String get lockedLook => 'Not yet';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String awayFarmed(int min) {
    return 'Mochi farmed for $min minutes while you were away';
  }

  @override
  String get claim => 'Collect';

  @override
  String get hatch => 'Hatch';

  @override
  String useEgg(int n) {
    return '🥚 Egg ($n)';
  }

  @override
  String adFree(int n) {
    return '📺 Free · $n left';
  }

  @override
  String fishHatch(int cost, int n) {
    return '🐟 $cost · $n left';
  }

  @override
  String odds(int c, int r, int l, int pity) {
    return 'Common $c% · Rare $r% · Legend $l% · Legend guaranteed in $pity';
  }

  @override
  String get askAge => 'How old are you?';

  @override
  String get changeAge => '👨‍👩‍👧 Change the player\'s age (grown-ups)';

  @override
  String get classOutfits =>
      'Class outfits (Mochi wears the chosen class\'s outfit)';

  @override
  String looksFound(int n, int all) {
    return 'Looks knitted so far $n/$all';
  }

  @override
  String get saveOlder =>
      'Couldn\'t open the latest save 😿 so we went on from the one before (the old save is kept)';

  @override
  String get saveNew =>
      'Couldn\'t open the save 😿 so a new game started (the old save is kept)';

  @override
  String get libraryTitle => 'Owl Library';

  @override
  String statNode(String stat, String per, String now) {
    return '$stat +$per%/level (now +$now%)';
  }

  @override
  String offlineNode(String cap) {
    return 'Collect for longer while away (now $cap h)';
  }

  @override
  String get queueNode => 'Research 2 things at once';

  @override
  String adSpeedUp(int min, int left) {
    return '📺 Watch an ad: $min+ min faster · $left left';
  }

  @override
  String get notifyResearch => '🔔 Tell me when research is done';

  @override
  String deskFree(int i) {
    return 'Desk $i is free — pick a topic below';
  }

  @override
  String get maxed => 'Maxed';

  @override
  String get researching => 'Researching…';

  @override
  String get queueFull => 'Desks full';

  @override
  String researchDone(String name, int lv) {
    return '🦉 Research done: $name Lv.$lv';
  }

  @override
  String get newPet => 'New friend!';

  @override
  String get starUp => 'Star up!';

  @override
  String treats(int n) {
    return 'Got treats 🍪 $n';
  }

  @override
  String deploySlots(int used, int all) {
    return 'In battle $used/$all';
  }

  @override
  String get deployHint => 'Tap a friend to send it to battle / rest';

  @override
  String get yay => 'Yay!';

  @override
  String get statAtk => 'Attack';

  @override
  String get statHp => 'Health';

  @override
  String get statDef => 'Defense';

  @override
  String get switchLanguage => '🌐 ภาษาไทย';

  @override
  String level(int lv) {
    return 'Lv.$lv';
  }

  @override
  String catTitle(String cls) {
    return 'Mochi · $cls';
  }

  @override
  String className(String cls) {
    String _temp0 = intl.Intl.selectLogic(
      cls,
      {
        'novice': 'Novice',
        'warrior': 'Warrior',
        'rogue': 'Rogue',
        'archer': 'Archer',
        'mage': 'Mage',
        'other': '$cls',
      },
    );
    return '$_temp0';
  }

  @override
  String cooldownSeconds(String sec) {
    return 'Cooldown $sec s';
  }
}
