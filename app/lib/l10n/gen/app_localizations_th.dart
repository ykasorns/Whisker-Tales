// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get navCharacter => 'ตัวละคร';

  @override
  String get navDungeon => 'ดันเจี้ยน';

  @override
  String get navHome => 'หลัก';

  @override
  String get navEvents => 'กิจกรรม';

  @override
  String get navShop => 'ร้านค้า';

  @override
  String get autoCraft => 'ถักอัตโนมัติ';

  @override
  String get betterStash => 'ของดีกว่า: เก็บรอเลือก';

  @override
  String get betterEquip => 'ของดีกว่า: ใส่ทันที';

  @override
  String get knit => 'ถักของ';

  @override
  String get noYarn => 'ไหมพรมหมด — สู้เพื่อเก็บเพิ่ม';

  @override
  String yarnLeft(int n) {
    return 'แตะก้อนไหมพรม · เหลือ $n ม้วน';
  }

  @override
  String chapterPage(int ch, int p) {
    return 'บท $ch · หน้า $p/10';
  }

  @override
  String farm(int done, int all) {
    return 'ฟาร์ม $done/$all';
  }

  @override
  String get tapForBoss => 'แตะเพื่อท้าบอส!';

  @override
  String get fightingBoss => 'กำลังสู้บอส';

  @override
  String get auto => 'AUTO';

  @override
  String get on => 'เปิด';

  @override
  String get off => 'ปิด';

  @override
  String unlockAt(int page) {
    return 'หน้า $page';
  }

  @override
  String get pickSlot => 'เลือกช่องที่จะถัก';

  @override
  String get worn => 'ที่ใส่อยู่';

  @override
  String get newItem => 'ของใหม่';

  @override
  String get equip => 'สวม';

  @override
  String recycle(int fish) {
    return 'รีไซเคิล +$fish🐟';
  }

  @override
  String get empty => 'ว่าง';

  @override
  String get comingSoon => 'เร็ว ๆ นี้';

  @override
  String get dungeonSoon => 'ดันเจี้ยนเปิดในเวอร์ชันถัดไป';

  @override
  String get tabCat => 'แมว';

  @override
  String get tabWardrobe => 'สมุดสะสม';

  @override
  String get tabPets => 'เพื่อนสัตว์';

  @override
  String get tabLibrary => 'ห้องสมุด';

  @override
  String get classPick => 'คลาส';

  @override
  String classAt(int lv) {
    return 'เลือกคลาสได้ที่ Lv.$lv';
  }

  @override
  String get skills => 'สกิล (ร่ายเอง)';

  @override
  String get dailyGift => 'ของขวัญรายวัน';

  @override
  String get yarnBundle => 'ไหมพรมพิเศษ';

  @override
  String adsLeft(int n) {
    return 'เหลือวันนี้ $n';
  }

  @override
  String get watch => 'ดู 📺';

  @override
  String get supporterPack => 'แพ็กผู้สนับสนุน';

  @override
  String get supporterDesc => 'ซ่อนปุ่มโฆษณาทุกจุด · ไม่มีของที่ทำให้เก่งขึ้น';

  @override
  String get askParent => 'ให้ผู้ปกครองช่วยซื้อ';

  @override
  String get gateTitle => 'สำหรับผู้ปกครอง 👨‍👩‍👧';

  @override
  String gateAsk(String q) {
    return '$q เท่ากับเท่าไร?';
  }

  @override
  String get gateWrong => 'ยังไม่ถูก ลองข้อใหม่นะ';

  @override
  String get gateExpired => 'หมดเวลาแล้ว ให้ผู้ปกครองยืนยันอีกครั้งนะ';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get shopClosed => 'ร้านยังไม่เปิดในตอนนี้';

  @override
  String get owned => 'มีแล้ว ✓';

  @override
  String get buying => 'กำลังเปิดหน้าชำระเงิน…';

  @override
  String get bought => 'ได้รับแล้ว 🎉 ขอบคุณที่สนับสนุน!';

  @override
  String get payPending => 'รอการยืนยันการชำระเงิน ได้ของเมื่อจ่ายเสร็จ';

  @override
  String get buyFailed => 'ซื้อไม่สำเร็จ ลองใหม่อีกครั้งนะ';

  @override
  String get restorePurchases => 'กู้คืนการซื้อ';

  @override
  String get restoring => 'กำลังกู้คืนของที่เคยซื้อ…';

  @override
  String get gradeNames => 'ขาว,เขียว,ฟ้า,ม่วง,ทอง,รุ้ง';

  @override
  String get lockedLook => 'ยังไม่ได้';

  @override
  String get welcomeBack => 'ยินดีต้อนรับกลับ!';

  @override
  String awayFarmed(int min) {
    return 'ระหว่างที่ไม่อยู่ โมจิฟาร์มไป $min นาที';
  }

  @override
  String get claim => 'รับของ';

  @override
  String get hatch => 'ฟักไข่';

  @override
  String useEgg(int n) {
    return '🥚 ใช้ไข่ ($n)';
  }

  @override
  String adFree(int n) {
    return '📺 ฟรี เหลือ $n';
  }

  @override
  String fishHatch(int cost, int n) {
    return '🐟 $cost · เหลือ $n';
  }

  @override
  String odds(int c, int r, int l, int pity) {
    return 'ธรรมดา $c% · หายาก $r% · ตำนาน $l% · การันตีตำนานใน $pity ครั้ง';
  }

  @override
  String get askAge => 'อายุเท่าไหร่?';

  @override
  String get changeAge => '👨‍👩‍👧 แก้อายุผู้เล่น (ผู้ปกครอง)';

  @override
  String get classOutfits => 'ชุดประจำคลาส (โมจิใส่ชุดของคลาสที่เลือก)';

  @override
  String looksFound(int n, int all) {
    return 'ของที่เคยถักได้ $n/$all';
  }

  @override
  String get saveOlder =>
      'เปิดเซฟล่าสุดไม่ได้ 😿 เลยเล่นต่อจากเซฟก่อนหน้า (เก็บเซฟเดิมสำรองไว้แล้ว)';

  @override
  String get saveNew =>
      'เปิดเซฟเดิมไม่ได้ 😿 เลยเริ่มเกมใหม่ (เก็บเซฟเดิมสำรองไว้แล้ว)';

  @override
  String get libraryTitle => 'ห้องสมุดนกฮูก';

  @override
  String statNode(String stat, String per, String now) {
    return '$stat +$per%/เลเวล (ตอนนี้ +$now%)';
  }

  @override
  String offlineNode(String cap) {
    return 'เก็บของตอนออฟไลน์ได้นานขึ้น (ตอนนี้ $cap ชม.)';
  }

  @override
  String get queueNode => 'วิจัยได้ 2 อย่างพร้อมกัน';

  @override
  String adSpeedUp(int min, int left) {
    return '📺 ดูโฆษณา ลดเวลา $min นาทีขึ้นไป · เหลือ $left';
  }

  @override
  String get notifyResearch => '🔔 แจ้งเตือนเมื่อวิจัยเสร็จ';

  @override
  String deskFree(int i) {
    return 'โต๊ะ $i ว่าง — เลือกหัวข้อด้านล่าง';
  }

  @override
  String get maxed => 'สูงสุดแล้ว';

  @override
  String get researching => 'กำลังวิจัย…';

  @override
  String get queueFull => 'โต๊ะเต็ม';

  @override
  String researchDone(String name, int lv) {
    return '🦉 วิจัยเสร็จแล้ว: $name Lv.$lv';
  }

  @override
  String get newPet => 'เพื่อนใหม่!';

  @override
  String get starUp => 'ดาวเพิ่ม!';

  @override
  String treats(int n) {
    return 'ได้ขนม 🍪 $n';
  }

  @override
  String deploySlots(int used, int all) {
    return 'ออกรบ $used/$all';
  }

  @override
  String get deployHint => 'แตะเพื่อนเพื่อพาออกรบ / พัก';

  @override
  String get yay => 'เย้!';

  @override
  String get statAtk => 'พลังโจมตี';

  @override
  String get statHp => 'พลังชีวิต';

  @override
  String get statDef => 'พลังป้องกัน';

  @override
  String get music => '🎵 เพลง';

  @override
  String get sounds => '🔊 เสียงเอฟเฟกต์';

  @override
  String get shortHp => 'เลือด';

  @override
  String get shortAtk => 'โจมตี';

  @override
  String get shortDef => 'ป้องกัน';

  @override
  String get shortEvade => 'หลบ';

  @override
  String get shortCrit => 'คริ';

  @override
  String get shortSkill => 'สกิล';

  @override
  String get shortPower => 'พลัง';

  @override
  String get curFish => 'ปลาทอง';

  @override
  String get curYarn => 'ไหมพรม';

  @override
  String get curEggs => 'ไข่';

  @override
  String pityLabel(int n) {
    return 'การันตีอีก $n';
  }

  @override
  String get switchLanguage => '🌐 English';

  @override
  String level(int lv) {
    return 'Lv.$lv';
  }

  @override
  String catTitle(String cls) {
    return 'โมจิ · $cls';
  }

  @override
  String className(String cls) {
    String _temp0 = intl.Intl.selectLogic(
      cls,
      {
        'novice': 'ฝึกหัด',
        'warrior': 'นักรบ',
        'rogue': 'โจร',
        'archer': 'นักธนู',
        'mage': 'นักเวท',
        'other': '$cls',
      },
    );
    return '$_temp0';
  }

  @override
  String cooldownSeconds(String sec) {
    return 'คูลดาวน์ $sec วิ';
  }
}
