import 'package:flutter/widgets.dart';

/// UI strings, TH + EN (contract §5: no hard-coded text in widgets). A small
/// map until T-004 moves them to .arb files.
class S {
  const S(this.lang);
  final String lang;

  static S of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangScope>()?.lang == 'en'
          ? en
          : th;
  static const th = S('th');
  static const en = S('en');

  String _t(String k) => (lang == 'en' ? _en : _th)[k] ?? _th[k] ?? k;

  String get navCharacter => _t('nav.character');
  String get navDungeon => _t('nav.dungeon');
  String get navHome => _t('nav.home');
  String get navEvents => _t('nav.events');
  String get navShop => _t('nav.shop');
  String get autoCraft => _t('auto_craft');
  String get betterStash => _t('better.stash');
  String get betterEquip => _t('better.equip');
  String get knit => _t('knit');
  String get noYarn => _t('no_yarn');
  String yarnLeft(int n) => _t('yarn_left').replaceAll('{n}', '$n');
  String chapterPage(int ch, int p) =>
      _t('chapter_page').replaceAll('{c}', '$ch').replaceAll('{p}', '$p');
  String farm(int done, int all) =>
      _t('farm').replaceAll('{d}', '$done').replaceAll('{a}', '$all');
  String get tapForBoss => _t('tap_boss');
  String get fightingBoss => _t('fighting_boss');
  String get auto => _t('auto');
  String get on => _t('on');
  String get off => _t('off');
  String unlockAt(int page) => _t('unlock_at').replaceAll('{p}', '$page');
  String get pickSlot => _t('pick_slot');
  String get worn => _t('worn');
  String get newItem => _t('new_item');
  String get equip => _t('equip');
  String recycle(int fish) => _t('recycle').replaceAll('{f}', '$fish');
  String get empty => _t('empty');
  String get comingSoon => _t('coming_soon');
  String get dungeonSoon => _t('dungeon_soon');
  String get tabCat => _t('tab.cat');
  String get tabWardrobe => _t('tab.wardrobe');
  String get tabPets => _t('tab.pets');
  String get tabLibrary => _t('tab.library');
  String get classPick => _t('class_pick');
  String classAt(int lv) => _t('class_at').replaceAll('{lv}', '$lv');
  String get skills => _t('skills');
  String get dailyGift => _t('daily_gift');
  String get yarnBundle => _t('yarn_bundle');
  String adsLeft(int n) => _t('ads_left').replaceAll('{n}', '$n');
  String get watch => _t('watch');
  String get supporterPack => _t('supporter_pack');
  String get supporterDesc => _t('supporter_desc');
  String get askParent => _t('ask_parent');
  String get gradeNames => _t('grades');
  String get lockedLook => _t('locked_look');
  String get welcomeBack => _t('welcome_back');
  String awayFarmed(int min) => _t('away_farmed').replaceAll('{m}', '$min');
  String get claim => _t('claim');
  String get hatch => _t('hatch');
  String useEgg(int n) => _t('use_egg').replaceAll('{n}', '$n');
  String adFree(int n) => _t('ad_free').replaceAll('{n}', '$n');
  String fishHatch(int cost, int n) =>
      _t('fish_hatch').replaceAll('{c}', '$cost').replaceAll('{n}', '$n');
  String odds(int c, int r, int l, int pity) => _t('odds')
      .replaceAll('{c}', '$c')
      .replaceAll('{r}', '$r')
      .replaceAll('{l}', '$l')
      .replaceAll('{p}', '$pity');
  String get libraryTitle => _t('library_title');
  String statNode(String stat, String per, String now) => _t('stat_node')
      .replaceAll('{s}', _t('stat.$stat'))
      .replaceAll('{p}', per)
      .replaceAll('{n}', now);
  String offlineNode(String cap) => _t('offline_node').replaceAll('{c}', cap);
  String get queueNode => _t('queue_node');
  String adSpeedUp(int min, int left) =>
      _t('ad_speed_up').replaceAll('{m}', '$min').replaceAll('{n}', '$left');
  String get notifyResearch => _t('notify_research');
  String deskFree(int i) => _t('desk_free').replaceAll('{i}', '$i');
  String get maxed => _t('maxed');
  String get researching => _t('researching');
  String get queueFull => _t('queue_full');
  String researchDone(String name, int lv) =>
      _t('research_done').replaceAll('{x}', name).replaceAll('{lv}', '$lv');
  String get newPet => _t('new_pet');
  String get starUp => _t('star_up');
  String treats(int n) => _t('treats').replaceAll('{n}', '$n');
  String deploySlots(int used, int all) =>
      _t('deploy_slots').replaceAll('{u}', '$used').replaceAll('{a}', '$all');
  String get deployHint => _t('deploy_hint');
  String get yay => _t('yay');

  static const _th = {
    'nav.character': 'ตัวละคร',
    'nav.dungeon': 'ดันเจี้ยน',
    'nav.home': 'หลัก',
    'nav.events': 'กิจกรรม',
    'nav.shop': 'ร้านค้า',
    'auto_craft': 'ถักอัตโนมัติ',
    'better.stash': 'ของดีกว่า: เก็บรอเลือก',
    'better.equip': 'ของดีกว่า: ใส่ทันที',
    'knit': 'ถักของ',
    'no_yarn': 'ไหมพรมหมด — สู้เพื่อเก็บเพิ่ม',
    'yarn_left': 'แตะก้อนไหมพรม · เหลือ {n} ม้วน',
    'chapter_page': 'บท {c} · หน้า {p}/10',
    'farm': 'ฟาร์ม {d}/{a}',
    'tap_boss': 'แตะเพื่อท้าบอส!',
    'fighting_boss': 'กำลังสู้บอส',
    'auto': 'AUTO',
    'on': 'เปิด',
    'off': 'ปิด',
    'unlock_at': 'หน้า {p}',
    'pick_slot': 'เลือกช่องที่จะถัก',
    'worn': 'ที่ใส่อยู่',
    'new_item': 'ของใหม่',
    'equip': 'สวม',
    'recycle': 'รีไซเคิล +{f}🐟',
    'empty': 'ว่าง',
    'coming_soon': 'เร็ว ๆ นี้',
    'dungeon_soon': 'ดันเจี้ยนเปิดในเวอร์ชันถัดไป',
    'tab.cat': 'แมว',
    'tab.wardrobe': 'ตู้เสื้อผ้า',
    'tab.pets': 'เพื่อนสัตว์',
    'tab.library': 'ห้องสมุด',
    'class_pick': 'คลาส',
    'class_at': 'เลือกคลาสได้ที่ Lv.{lv}',
    'skills': 'สกิล (ร่ายเอง)',
    'daily_gift': 'ของขวัญรายวัน',
    'yarn_bundle': 'ไหมพรมพิเศษ',
    'ads_left': 'เหลือวันนี้ {n}',
    'watch': 'ดู 📺',
    'supporter_pack': 'แพ็กผู้สนับสนุน',
    'supporter_desc': 'ซ่อนปุ่มโฆษณา + ชุดพิเศษ · ไม่มีของที่ทำให้เก่งขึ้น',
    'ask_parent': 'ให้ผู้ปกครองช่วยซื้อ',
    'grades': 'ขาว,เขียว,ฟ้า,ม่วง,ทอง,รุ้ง',
    'locked_look': 'ยังไม่ได้',
    'welcome_back': 'ยินดีต้อนรับกลับ!',
    'away_farmed': 'ระหว่างที่ไม่อยู่ โมจิฟาร์มไป {m} นาที',
    'claim': 'รับของ',
    'hatch': 'ฟักไข่',
    'use_egg': '🥚 ใช้ไข่ ({n})',
    'ad_free': '📺 ฟรี เหลือ {n}',
    'fish_hatch': '🐟 {c} · เหลือ {n}',
    'odds': 'ธรรมดา {c}% · หายาก {r}% · ตำนาน {l}% · การันตีตำนานใน {p} ครั้ง',
    'library_title': 'ห้องสมุดนกฮูก',
    'stat.atk': 'พลังโจมตี',
    'stat.hp': 'พลังชีวิต',
    'stat.def': 'พลังป้องกัน',
    'stat_node': '{s} +{p}%/เลเวล (ตอนนี้ +{n}%)',
    'offline_node': 'เก็บของตอนออฟไลน์ได้นานขึ้น (ตอนนี้ {c} ชม.)',
    'queue_node': 'วิจัยได้ 2 อย่างพร้อมกัน',
    'ad_speed_up': '📺 ดูโฆษณา ลดเวลา {m} นาทีขึ้นไป · เหลือ {n}',
    'notify_research': '🔔 แจ้งเตือนเมื่อวิจัยเสร็จ',
    'desk_free': 'โต๊ะ {i} ว่าง — เลือกหัวข้อด้านล่าง',
    'maxed': 'สูงสุดแล้ว',
    'researching': 'กำลังวิจัย…',
    'queue_full': 'โต๊ะเต็ม',
    'research_done': '🦉 วิจัยเสร็จแล้ว: {x} Lv.{lv}',
    'new_pet': 'เพื่อนใหม่!',
    'star_up': 'ดาวเพิ่ม!',
    'treats': 'ได้ขนม 🍪 {n}',
    'deploy_slots': 'ออกรบ {u}/{a}',
    'deploy_hint': 'แตะเพื่อนเพื่อพาออกรบ / พัก',
    'yay': 'เย้!',
  };
  static const _en = {
    'nav.character': 'Cat',
    'nav.dungeon': 'Dungeon',
    'nav.home': 'Home',
    'nav.events': 'Events',
    'nav.shop': 'Shop',
    'auto_craft': 'Auto-knit',
    'better.stash': 'Better: keep for me',
    'better.equip': 'Better: wear now',
    'knit': 'Knit',
    'no_yarn': 'Out of yarn — fight for more',
    'yarn_left': 'Tap the yarn · {n} left',
    'chapter_page': 'Ch {c} · Page {p}/10',
    'farm': 'Farm {d}/{a}',
    'tap_boss': 'Tap to fight the boss!',
    'fighting_boss': 'Boss fight',
    'auto': 'AUTO',
    'on': 'on',
    'off': 'off',
    'unlock_at': 'Page {p}',
    'pick_slot': 'Pick a slot to knit',
    'worn': 'Wearing',
    'new_item': 'New',
    'equip': 'Wear',
    'recycle': 'Recycle +{f}🐟',
    'empty': 'Empty',
    'coming_soon': 'Coming soon',
    'dungeon_soon': 'Dungeons open in the next version',
    'tab.cat': 'Cat',
    'tab.wardrobe': 'Wardrobe',
    'tab.pets': 'Pets',
    'tab.library': 'Library',
    'class_pick': 'Class',
    'class_at': 'Pick a class at Lv.{lv}',
    'skills': 'Skills (auto)',
    'daily_gift': 'Daily gift',
    'yarn_bundle': 'Yarn bundle',
    'ads_left': '{n} left today',
    'watch': 'Watch 📺',
    'supporter_pack': 'Supporter Pack',
    'supporter_desc': 'Hides ad buttons + a special outfit · no power',
    'ask_parent': 'Ask a grown-up to buy',
    'grades': 'White,Green,Blue,Purple,Gold,Rainbow',
    'locked_look': 'Not yet',
    'welcome_back': 'Welcome back!',
    'away_farmed': 'Mochi farmed for {m} minutes while you were away',
    'claim': 'Collect',
    'hatch': 'Hatch',
    'use_egg': '🥚 Egg ({n})',
    'ad_free': '📺 Free · {n} left',
    'fish_hatch': '🐟 {c} · {n} left',
    'odds': 'Common {c}% · Rare {r}% · Legend {l}% · Legend guaranteed in {p}',
    'library_title': 'Owl Library',
    'stat.atk': 'Attack',
    'stat.hp': 'Health',
    'stat.def': 'Defense',
    'stat_node': '{s} +{p}%/level (now +{n}%)',
    'offline_node': 'Collect for longer while away (now {c} h)',
    'queue_node': 'Research 2 things at once',
    'ad_speed_up': '📺 Watch an ad: {m}+ min faster · {n} left',
    'notify_research': '🔔 Tell me when research is done',
    'desk_free': 'Desk {i} is free — pick a topic below',
    'maxed': 'Maxed',
    'researching': 'Researching…',
    'queue_full': 'Desks full',
    'research_done': '🦉 Research done: {x} Lv.{lv}',
    'new_pet': 'New friend!',
    'star_up': 'Star up!',
    'treats': 'Got treats 🍪 {n}',
    'deploy_slots': 'In battle {u}/{a}',
    'deploy_hint': 'Tap a friend to send it to battle / rest',
    'yay': 'Yay!',
  };
}

/// Which language the UI speaks (`settings.lang` in the save; Thai default).
class LangScope extends InheritedWidget {
  const LangScope({super.key, required this.lang, required super.child});
  final String lang;

  @override
  bool updateShouldNotify(LangScope old) => old.lang != lang;
}
