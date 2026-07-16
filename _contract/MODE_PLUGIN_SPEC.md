# MODE_PLUGIN_SPEC.md — Whisker Tales 🔌

**Version:** 1.0 | **สถานะ:** ส่วนหนึ่งของ GAME_CONTRACT v1.1 (บังคับใช้กับทุก agent)
**เจตนา:** โหมดเกมใหม่ (ดันเจี้ยน, ตะลุยไร้จุดจบ, event ฯลฯ) ต้องเพิ่มได้แบบ "เขียน module แยก แล้วเสียบเข้า" — **ห้ามแตะ core engine**

---

## 1. โครงสร้าง 3 ชั้น

```
┌─────────────────────────────────────────────────┐
│  ชั้น 3: ACTIVITIES (กิจกรรม)                     │  data-only ไม่มีโค้ด
│  login bonus / challenge ประจำวัน / ลดราคาร้านค้า │  ← activities.json
├─────────────────────────────────────────────────┤
│  ชั้น 2: GAME MODES (โหมด)                        │  package แยก 1 โหมด = 1 package
│  Story / Endless / Dungeon / ...                 │  ← implement IGameMode
├─────────────────────────────────────────────────┤
│  ชั้น 1: CORE ENGINE (ห้าม fork)                  │  wt_core package เดียว
│  combat · items · talents · save · audio ·       │
│  ui shells · RunManager · ModeRegistry           │
└─────────────────────────────────────────────────┘
```

**กฎทอง:** โหมดใหม่**ปรับพารามิเตอร์** engine ผ่าน config — ไม่เคยแก้/copy โค้ด engine ถ้าโหมดไหนทำไม่ได้ด้วย config ที่มี = ยกระดับเป็นคำขอขยาย core (ผ่าน Opus→Advisor) ไม่ใช่ hack ในโหมด

## 2. โครง Package (แก้จาก single-app เป็น melos-style monorepo)

```
whisker_tales/
├── packages/
│   ├── wt_core/            # engine ทั้งหมด (module เดิมทุกตัวย้ายมาอยู่ที่นี่)
│   ├── wt_mode_story/      # โหมดหลัก MVP (biome + boss)
│   ├── wt_mode_endless/    # ตะลุยไร้จุดจบ (post-launch — โครงตัวอย่างใน §6)
│   └── wt_mode_dungeon/    # ดันเจี้ยน (อนาคต)
└── app/                    # ตัวประกอบ: main.dart → registerModes()
```

การเพิ่มโหมด = สร้าง package ใหม่ + ลงทะเบียน 1 บรรทัดใน `app/lib/modes.dart` — จบ ไม่มีไฟล์อื่นใน core ถูกแตะ

## 3. สัญญา IGameMode (หัวใจของ spec นี้)

```dart
abstract class GameMode {
  /// id คงที่ตลอดชีพ ใช้เป็น namespace ใน save
  String get id;                                    // "story" | "endless" | "dungeon"

  /// อ่านจาก modes/<id>/manifest.json (ดู §4)
  ModeManifest get manifest;

  /// การ์ดเมนูที่จะโผล่ในหมู่บ้าน — hub ไม่รู้จักโหมดล่วงหน้า
  Widget buildHubCard(BuildContext ctx, ModeSaveState s);

  /// สร้าง config ของ run นี้ (ความยาก, modifier, seed)
  RunConfig createRunConfig(ModeSaveState s);

  /// ★ จุดต่างหลักของแต่ละโหมด — แหล่งกำเนิด encounter
  EncounterSource encounterSource(RunConfig c);

  /// เงื่อนไขจบ run
  WinCondition winCondition(RunConfig c);

  /// แปลงผล run → รางวัล (ปลาทอง, unlock, สถิติโหมด)
  RewardResult resolveReward(RunResult r, ModeSaveState s);

  /// save เฉพาะโหมด (core เก็บให้ใน namespace modes.<id>)
  ModeSaveState decodeSave(Map<String, dynamic> json);
  Map<String, dynamic> encodeSave(ModeSaveState s);
}
```

### EncounterSource — abstraction ที่ทำให้ RunManager ใช้ร่วมได้ทุกโหมด
```dart
abstract class EncounterSource {
  /// คืน encounter ถัดไป หรือ null = ถึงจุดจบตามโครงสร้างโหมด
  Encounter? next(int depth, Random rng);
  /// ให้ UI วาด node map ล่วงหน้า (โหมด infinite คืนเท่าที่มองเห็น)
  List<EncounterPreview> preview(int depth, int count);
}
```
| โหมด | พฤติกรรม next() |
|---|---|
| Story | เดินตาม node list ที่ gen จาก seed (8–10 จบที่ boss) — จำกัดจบ |
| Endless | generator ไม่รู้จบ ความยาก = f(depth), มี mini-boss ทุก 10 depth, `null` ไม่มีวันคืน (จบด้วยการตายเท่านั้น) |
| Dungeon | ต่อ "ชั้น": ห้องหลายห้องต่อชั้น หาบันได/กุญแจ ลงชั้นถัดไป |

RunManager, combat, items, talents, UI panel **ไม่ต้องรู้เลย**ว่ากำลังเล่นโหมดไหน — เห็นแค่ Encounter ที่ไหลมาจาก source

## 4. Mode Manifest (data-driven การเปิด/ปิด)

`packages/wt_mode_<id>/assets/manifest.json`
```json
{
  "id": "endless",
  "name_th": "ตะลุยไร้จุดจบ", "name_en": "Endless Tale",
  "icon": "mode_endless",
  "order": 2,
  "enabled": true,
  "min_app_version": "1.2.0",
  "unlock": { "type": "flag", "flag": "story_boss1_cleared" }
}
```
- หมู่บ้าน (hub) สร้างเมนูจาก `ModeRegistry` เรียงตาม `order` — โหมดที่ `enabled:false` หรือยังไม่ unlock จะแสดงเป็นการ์ดล็อก 🔒 หรือซ่อน
- **ship โค้ดโหมดล่วงหน้าแบบ dormant ได้** แล้วค่อยเปิดใน patch เล็ก (อนาคตต่อ remote config ได้ที่จุดนี้จุดเดียว)
- `unlock` เป็น vocabulary จำกัด: `flag | fish_total | boss_cleared` — เพิ่ม type ใหม่ต้องผ่าน Opus

## 5. Save Schema v2 (namespace ต่อโหมด)

```json
{
  "save_version": 2,
  "profile": { "goldfish": 0, "unlocked_cats": ["mochi"], "unlocked_cosmetics": [], "village_level": 1, "flags": ["story_boss1_cleared"] },
  "stats":   { "total_runs": 0 },
  "modes": {
    "story":   { "best_node": 8, "bosses_cleared": ["paper_wolf"] },
    "endless": { "best_depth": 42, "runs": 7 }
  },
  "settings": { "lang": "th", "bgm": true, "sfx": true },
  "updated_at": "ISO8601"
}
```
- `profile`/`stats` = ของกลาง แชร์ทุกโหมด | `modes.<id>` = โหมดใครโหมดมัน core ไม่ตีความ
- Cloud conflict rule ขยาย: เทียบ `stats.total_runs` → `profile.goldfish` → `updated_at` (เหมือนเดิม — ก้อน modes ตามผู้ชนะทั้งก้อน)
- Migration v1→v2: ย้าย field เดิมเข้า `modes.story` + สร้าง `flags`

## 6. ตัวอย่างจริง: เพิ่มโหมด "ตะลุยไร้จุดจบ" ต้องทำอะไรบ้าง

```
packages/wt_mode_endless/
├── assets/manifest.json          # ข้อมูลโหมด (§4)
├── lib/endless_mode.dart         # class EndlessMode implements GameMode (~80 บรรทัด)
├── lib/endless_source.dart       # EncounterSource: difficulty curve f(depth)
├── lib/endless_hub_card.dart     # การ์ดเมนู + โชว์ best depth
└── test/conformance_test.dart    # ผ่าน ModeConformanceTest (§7)
```
แล้วเพิ่มใน `app/lib/modes.dart`:
```dart
ModeRegistry.register(EndlessMode());   // ← บรรทัดเดียว
```
**ศูนย์ไฟล์ใน wt_core ถูกแก้** — นี่คือ acceptance test ของสถาปัตยกรรมนี้

## 7. ModeConformanceTest (กันโหมดเถื่อน)

ทุกโหมดต้องผ่าน test suite กลางจาก core:
- encode/decode save ไป-กลับได้ข้อมูลครบ (roundtrip)
- `next()` ไม่ throw ที่ depth 0–1000 / seed เดิมให้ผลเดิม (ถ้าโหมด deterministic)
- manifest ผ่าน schema validation
- ไม่ import ไฟล์ภายใน wt_core นอกเหนือจาก public API (`package:wt_core/wt_core.dart` เท่านั้น — บังคับด้วย lint rule)
- rewardResolve ไม่ให้ item/currency นอก vocabulary กลาง

## 8. Activities (ชั้น 3 — เบากว่าโหมด: data-only)

กิจกรรมชั่วคราวไม่ต้องมี package: core มี **ActivityRunner** อ่าน `design/data/activities.json`
```json
{ "activities": [
  { "id": "songkran_2027", "window": { "start": "2027-04-10", "end": "2027-04-17" },
    "type": "challenge_seed", "payload": { "mode": "story", "seed": 20270413, "bonus_fish_pct": 50 } },
  { "id": "weekend_sale", "window": {...}, "type": "shop_sale", "payload": { "discount_pct": 20 } }
] }
```
type vocabulary เริ่มต้น: `login_bonus | challenge_seed | shop_sale | double_fish` — กิจกรรมใหม่ในอนาคต = เพิ่ม JSON ไม่ต้อง build ใหม่ (อ่านจาก bundle ตอนนี้ / ต่อ remote fetch ได้ภายหลังโดยผ่าน compliance review ก่อน)

## 9. ผลกระทบต่อ Task เดิม (สรุป — รายละเอียดใน card ที่แก้แล้ว)

| Task | เปลี่ยนอะไร |
|---|---|
| T-002 | contracts เพิ่ม `GameMode`, `EncounterSource`, `ModeRegistry` |
| T-005 | RunManager รับ `EncounterSource` แทน node list ตรงๆ (mode-agnostic) |
| T-020 | หมู่บ้านสร้างเมนูโหมดจาก ModeRegistry + การ์ดล็อก |
| T-022 | save schema เริ่มที่ v2 (namespace modes) — ไม่ต้อง migrate จริงเพราะยังไม่มี user |
| ใหม่ T-031 | Mode framework + ย้าย Story เป็น `wt_mode_story` (โหมดแรกที่พิสูจน์ plugin) |
| ใหม่ T-032 | `wt_mode_endless` vertical slice — acceptance: **แก้ core = 0 ไฟล์** |

---
*แก้ไข spec นี้ได้โดย Advisor + YK เท่านั้น — โหมดที่ต้องการเกินสัญญา IGameMode ให้เปิด BLOCKED แล้ว escalate*
