# GAME_CONTRACT.md — Whisker Tales 🐱📖

**Version:** 2.1 | **อ้างอิง:** GDD_WhiskerTales_v0.5.md + v0.4.md + MODE_PLUGIN_SPEC.md (+ GDD v0.3 สำหรับโหมดท้าทายนิทาน)
> **v2.1 (D-004, 2026-10-18):** §3 เพิ่ม module `cat_class`, `wardrobe`, `rig` · `combat` ไม่มี input ระหว่างสู้ (idle ล้วน) · §4.6 Save v3 เพิ่ม `cat`, `wardrobe`, `gear.stash`, `gear.unlocked_slots`, `settings.speed`
> **v2.0 (D-002, 2026-10-12, YK approved · Advisor review pending):** pivot เป็น idle RPG — §2 เพิ่ม `tools/` · §3 เพิ่ม module `idle_loop` `offline_reward` `gear_basket` `pets` `research` `ads` `age_gate` + `combat` เป็น deterministic sim + buff engine · §4.4 save schema v3 + conflict rule ใหม่ + กฎนาฬิกา · §4.5 effect vocabulary → buff action/hook · §5 อนุญาต rewarded ads แบบมีเงื่อนไข
> **v1.2 (D-001):** แก้ §2/§3 ให้ตรงกับ layout monorepo ที่ v1.1 ประกาศไว้จริง — `lib/` single-app เดิมเลิกใช้ เปลี่ยนเป็น `packages/wt_core` (module ทั้งหมดย้ายมาที่ `lib/src/<module>/` + barrel `lib/wt_core.dart`) + `packages/wt_mode_*` + `app/`
> **v1.1:** เพิ่ม Game Mode Plugin Architecture — โหมด/กิจกรรมใหม่เป็น package แยก เสียบผ่าน ModeRegistry (รายละเอียดทั้งหมดใน MODE_PLUGIN_SPEC.md) | save schema เริ่มที่ v2 (namespace ต่อโหมด) | โครง repo เปลี่ยนเป็น packages/wt_core + packages/wt_mode_* + app/
**บังคับใช้กับ:** ทุก agent ในโปรเจกต์ — Opus (Orchestrator/PM) และ Sonnet (Worker) ต้องอ่านไฟล์นี้ก่อนเริ่มทุก task

---

## 1. Roles & Authority

| Role | Model | อำนาจ | ห้าม |
|---|---|---|---|
| **Advisor** | Fable 5 | ตัดสิน design trade-off, อนุมัติเปลี่ยน scope/GDD, review architecture | — |
| **Orchestrator (PM)** | Opus | แตก task, กำหนด interface, review งาน Sonnet, merge, อัพเดต DISPATCH | เขียน feature code เอง / เปลี่ยน GDD โดยไม่ผ่าน Advisor |
| **Worker** | Sonnet | implement ตาม task card, เขียน test, รายงานผล | แตะไฟล์นอก scope ของ task / เพิ่ม dependency / เปลี่ยน interface กลาง |

**Escalation:** Sonnet ติดปัญหา interface ไม่พอ → เขียนลง `BLOCKED.md` แล้วหยุด ห้ามแก้ contract เอง → Opus ตัดสิน → ถ้ากระทบ GDD ส่งต่อ Advisor

---

## 2. Repository Structure & Permissions

```
whisker_tales/
├── _contract/            # READ ONLY (ทุก agent)
│   ├── GAME_CONTRACT.md
│   ├── GDD_WhiskerTales_v0.4.md   # spec หลัก
│   ├── GDD_WhiskerTales_v0.3.md   # superseded — ใช้เป็น spec โหมดนิทานผจญภัยเท่านั้น
│   └── ART_PROMPT_BIBLE.md
├── _dispatch/            # Opus WRITE / Sonnet ย้ายไฟล์ claim เท่านั้น
│   ├── todo/             # task cards รอ claim
│   ├── doing/            # move-to-claim: Sonnet ย้ายไฟล์มาที่นี่ = จองงาน
│   ├── review/           # Sonnet ทำเสร็จย้ายมา รอ Opus review
│   └── done/
├── design/               # READ ONLY สำหรับ Sonnet (Opus/Advisor เขียน)
│   ├── data/             # JSON content: relics.json, talents.json, monsters.json, events.json
│   └── balance/          # ตาราง balancing
├── assets/
│   ├── raw/              # READ ONLY — art จาก AI pipeline (ก่อน process)
│   └── game/             # WRITE (task art-integration เท่านั้น) — sprite/audio พร้อมใช้
├── packages/             # WRITE — melos-style monorepo, Dart source (ตาม module ownership ข้อ 3)
│   ├── wt_core/          # engine เดียว — module เดิมทุกตัวย้ายมาอยู่ที่นี่ (ห้าม fork)
│   │   ├── lib/
│   │   │   ├── wt_core.dart   # public API barrel — จุดเดียวที่ package ภายนอก import ได้
│   │   │   └── src/<module>/  # implementation ต่อโมดูล ดูตาราง §3
│   │   └── test/              # unit test ของ wt_core
│   ├── wt_mode_story/    # โหมดหลัก MVP (biome + boss)
│   ├── wt_mode_endless/  # ตะลุยไร้จุดจบ (T-032, ship dormant enabled:false ก่อน launch)
│   └── wt_mode_dungeon/  # อนาคต
├── app/                  # WRITE — ตัวประกอบแอป
│   ├── lib/
│   │   ├── main.dart
│   │   ├── modes.dart    # registerModes() — จุดเดียวที่ลงทะเบียนโหมดใหม่
│   │   └── l10n/         # string ของแอป (content ยังมาจาก design/data JSON เหมือนเดิม)
│   ├── android/
│   └── ios/
├── tools/
│   └── balance_sim/      # pure-Dart pacing sim (Opus/Advisor เป็นเจ้าของ) อ่าน design/balance/idle_balance_v1.json — ไม่ใช่ส่วนของแอป
├── BLOCKED.md            # Sonnet append-only
└── DECISIONS.md          # Opus append-only — log การตัดสินใจทุกครั้ง
```

**กฎเหล็ก:** ไฟล์ใน `_contract/` และ `design/data/*.json` schema คือ source of truth — โค้ดต้องตาม data ไม่ใช่ data ตามโค้ด

---

## 3. Module Boundaries (1 task card = 1 module เท่านั้น)

| Module | Path | หน้าที่ | พึ่งพาได้ |
|---|---|---|---|
| `core_loop` | `packages/wt_core/lib/src/core/` | GameState, RunManager, state machine (walk→encounter→resolve→walk) | — |
| `encounter_gen` | `packages/wt_core/lib/src/encounter/` | สร้าง node map จาก seed, สุ่ม encounter ตามสัดส่วน GDD §3.3 | core |
| `combat` | `packages/wt_core/lib/src/combat/` | **deterministic sim** (fixed-point + seeded RNG), stat/anti-stat, damage pipeline (GDD v0.4 §4.2), **buff engine** (§4.3), skill, dodge/telegraph, PowerScore — ใช้ร่วมทุกโหมด | core |
| `idle_loop` | `packages/wt_core/lib/src/idle/` | เล่ม/บท/หน้า, wave source ไม่รู้จบ, boss gate, เลือกหน้าฟาร์ม, รายได้ต่อคลื่น (โหมดหลัก — **ไม่ใช่ GameMode plugin**, ดู D-002) | core, combat |
| `offline_reward` | `packages/wt_core/lib/src/offline/` | คำนวณรางวัลออฟไลน์จาก GameClock + cap (GDD §8) | core, idle_loop |
| `gear_basket` | `packages/wt_core/lib/src/gear/` | ตะกร้าถักเอง: ตารางเกรด, pity, เทียบ/สวม/รีไซเคิล, อัพช่อง, auto-craft (GDD §3) | core, combat |
| `pets` | `packages/wt_core/lib/src/pets/` | roster, ดาว, ช่องออกรบ, ฟักไข่ + quota/วัน + pity (GDD §6) | core, combat, ads |
| `research` | `packages/wt_core/lib/src/research/` | tree ห้องสมุด, timer, คิว, hook ลดเวลา (GDD §7) | core, ads |
| `ads` | `packages/wt_core/lib/src/ads/` | `AdService` interface + fake impl, placement registry จาก JSON, **daily cap รวม/ต่อจุด (บังคับที่นี่ที่เดียว)**, โหมด non-personalized ตาม age band | core, save |
| `cat_class` | `packages/wt_core/lib/src/cat/` | เลเวล/EXP แมว, คลาส (เลือก Lv10, ขั้น 2 Lv40), ตัวคูณ stat คลาส, ปลดสกิลตามเลเวล (GDD v0.5 §3) | core, combat |
| `wardrobe` | `packages/wt_core/lib/src/wardrobe/` | แบบ (style) ที่ปลดแล้ว, หน้าตาที่เลือกต่อช่อง, สมุดสะสม, แบบจาก IAP (GDD v0.5 §4.2) | core, save |
| `rig` | `packages/wt_core/lib/src/rig/` | rig runtime: ชิ้นส่วน + pivot + attach point + keyframe JSON, ติดชิ้นอุปกรณ์ตามหน้าตาที่เลือก (GDD v0.5 §2) — render อย่างเดียว ไม่มี game logic | core |
| `age_gate` | `packages/wt_core/lib/src/age/` | age screen เป็นกลางตอนเปิดครั้งแรก → age band (`under13` / `13plus`) | core, save |
| `item_synergy` | `packages/wt_core/lib/src/items/` | relic/potion, synergy resolver (อ่าน relics.json) | core, combat |
| `talent_system` | `packages/wt_core/lib/src/talents/` | XP/level, talent pick, effect resolver (อ่าน talents.json) | core, combat |
| `meta_progression` | `packages/wt_core/lib/src/meta/` | currency ถาวร (ปลาทอง/ไหมพรม/ไข่/ขนม), ร้านนกฮูก, ปลดล็อกสกิล/ฟีเจอร์ตามบท, hub เมนู | core, save |
| `ui_panel` | `packages/wt_core/lib/src/ui/` | โซนล่าง 40% ทุก state + HUD + node map ลอย | ทุก module ผ่าน Riverpod provider เท่านั้น |
| `save_cloud` | `packages/wt_core/lib/src/save/` | local (Hive) + cloud sync (Game Center/Play Games), versioned save schema | core |
| `audio` | `packages/wt_core/lib/src/audio/` | BGM/SFX service | core |
| `iap_gate` | `packages/wt_core/lib/src/iap/` | in_app_purchase + parental gate + entitlement `no_ads` (รูปแบบรางวัลรอ GDD v0.4 §17 Q8 — ทำเป็น flag ก่อน) | meta, save |

**กฎ import:**
- ห้าม import ข้าม module โดยตรง — ทุกการสื่อสารผ่าน (1) Riverpod providers ที่ประกาศใน `packages/wt_core/lib/src/core/providers.dart` หรือ (2) interface abstract class ใน `packages/wt_core/lib/src/core/contracts/` เท่านั้น
- package ภายนอก wt_core (`app/`, `packages/wt_mode_*`) import ได้เฉพาะ barrel `package:wt_core/wt_core.dart` เท่านั้น ห้าม import `package:wt_core/src/...` ตรง — บังคับด้วย lint

---

## 4. Data Schemas (source of truth — เปลี่ยนต้องผ่าน Opus + bump version)

### 4.1 Relic (`design/data/relics.json`)
```json
{
  "schema_version": 1,
  "relics": [{
    "id": "electric_fur",
    "name_th": "ขนแมวไฟฟ้า", "name_en": "Electric Fur",
    "icon": "relic_electric_fur",
    "rarity": "common | rare | epic",
    "effects": [{ "trigger": "on_attack", "action": "spawn_spark", "params": { "damage_pct": 15 } }],
    "synergy": [{ "with": "echo_bell", "action": "spark_chain", "params": { "bounces": 2 } }]
  }]
}
```

### 4.2 Talent (`design/data/talents.json`)
```json
{
  "schema_version": 1,
  "trees": ["claw", "shadow", "magic"],
  "talents": [{
    "id": "claw_t1_sharpen",
    "tree": "claw", "tier": 1,
    "name_th": "ลับเล็บ", "name_en": "Sharpen",
    "icon": "talent_claw_sharpen",
    "effects": [{ "trigger": "passive", "action": "stat_mod", "params": { "stat": "atk", "pct": 15 } }],
    "requires": null
  }]
}
```

### 4.3 Monster / Event — โครงเดียวกัน: `id`, `name_th/en`, `icon`, `stats`/`choices`, `effects[]` (trigger/action/params)

### 4.4 Save File (versioned — สำคัญต่อ cloud sync)
> ⚠️ **v2.0: schema ด้านล่างเป็นของ v1.x (อ้างอิงประวัติ) — ใช้ §4.6 Save v3 แทน**
```json
{
  "save_version": 1,
  "profile": { "goldfish": 0, "unlocked_cats": ["mochi"], "unlocked_cosmetics": [], "village_level": 1 },
  "stats": { "total_runs": 0, "best_depth": 0 },
  "settings": { "lang": "th", "bgm": true, "sfx": true },
  "updated_at": "ISO8601"
}
```
- Cloud conflict rule: **ความคืบหน้ามากกว่าชนะ** (เทียบ total_runs → goldfish → updated_at)
- Migration: ทุกการ bump `save_version` ต้องมี migration function + test

### 4.5 Effect Vocabulary (v1.x — ใช้ในโหมดนิทานผจญภัย; v2.0 map เข้า buff engine ตาม §4.7)
`trigger`: `passive | on_attack | on_crit | on_dodge | on_skill | on_combat_end | on_level_up`
`action`: `stat_mod | spawn_spark | spark_chain | heal | speed_buff | counter | cooldown_mod | star_bomb` — เพิ่ม action ใหม่ = แก้ resolver ใน module เดียว + ขอ Opus อนุมัติ

### 4.6 Save v3 (v2.0)
```json
{
  "save_version": 3,
  "profile": { "goldfish": 0, "yarn": 0, "eggs": 0, "cookies": 0, "flags": [], "unlocked_cosmetics": [] },
  "idle": { "cleared_page": 0, "book": 1 },
  "gear": { "slots": [{ "item": null, "level": 0 }], "unlocked_slots": ["weapon", "hat", "shirt", "shoes"], "stash": { "slot_id": "item" }, "basket": { "level": 1, "exp": 0, "pity": 0 }, "auto_craft": { "on": false, "better": "stash | equip" } },
  "cat": { "level": 1, "exp": 0, "class": "novice", "tier": 0 },
  "wardrobe": { "unlocked": ["style_id"], "chosen": { "slot_id": "style_id" } },
  "pets": { "owned": { "pet_id": { "stars": 1, "level": 1 } }, "deployed": [], "pity": 0 },
  "research": { "levels": { "node_id": 0 }, "task": { "node": "node_id", "ends_at_utc": "ISO8601" } },
  "daily": { "date_key": "2026-10-12", "ads_used": { "pet_hatch": 0 }, "ads_total": 0, "fish_pulls": 0 },
  "clock": { "last_seen_utc": "ISO8601", "max_seen_utc": "ISO8601" },
  "age": { "band": "under13 | 13plus | unset" },
  "entitlements": { "no_ads": false },
  "modes": { "story": {}, "endless": {} },
  "settings": { "lang": "th", "bgm": true, "sfx": true, "speed": 1 },
  "updated_at": "ISO8601"
}
```
- **Cloud conflict rule (v3):** `idle.cleared_page` มากกว่าชนะ → PowerScore → `updated_at` · `clock.max_seen_utc` = ค่า max ของทั้งสองฝั่งเสมอ
- **กฎนาฬิกา (ไม่มี backend — เวลาเครื่องคือแหล่งเดียว):**
  - เวลาออฟไลน์ = `clamp(now − last_seen, 0, cap)` · ถ้า `now < max_seen` (ย้อนนาฬิกา) → ได้ 0 และไม่ลด `max_seen`
  - รีเซ็ต quota รายวันเมื่อ `date_key` (วันที่ท้องถิ่น) **มากกว่า** ค่าที่เก็บไว้เท่านั้น — ย้อนวันไม่รีเซ็ต
  - research `ends_at_utc` เทียบกับ `max(now, max_seen)` ไม่ใช่ `now` ตรง ๆ ไม่ให้ย้อนนาฬิกาแล้วงานถอยหลัง; เลื่อนนาฬิกาไปข้างหน้า = ได้ผลเหมือนรอจริง (ยอมรับ — ไม่มี backend) แต่ offline cap จำกัดผลเสีย
- Migration v2→v3: ยังไม่มี user จริง → ไม่ต้อง migrate (เหมือน D-001) แต่ต้องมี test decode v3

### 4.7 Buff Data (v2.0 — `design/data/buffs.json`)
```json
{ "schema_version": 1,
  "buffs": [{ "id": "claw_sharpen", "action": "attrib", "params": { "attr": "atk", "mode": "pct", "value": 15 },
              "duration_ms": -1, "group": "claw", "mutex": null, "stack_max": 1,
              "on_event": [{ "event": "crit", "add_buff": "claw_reset_cd" }] }] }
```
- `action` → class เดียวต่อ action ที่ override เฉพาะ hook (`onBegin/onEnd/onTick/onDamageDealt/onDamageTaken/onHeal/onStateEvent`)
- `on_event` = state trigger ยิง buff ต่อ (synergy เป็น data) · เพิ่ม `action` ใหม่ = แก้ `combat` module เดียว + Opus อนุมัติ
- relic/talent (§4.1/4.2) แปลง `effects[]` เป็น buff id ตอนโหลด

---

## 5. Technical Standards

- **Flutter 3.x + Flame** (เวอร์ชันล็อกใน pubspec — Sonnet ห้ามอัพเกรด)
- **State:** Riverpod เท่านั้น — ห้าม setState ข้าม widget, ห้าม global mutable
- **Layout:** `GameWidget` (Flame) สูง 60% ของ safe area / Flutter UI panel 40% — ratio เป็น constant ใน `packages/wt_core/lib/src/core/layout.dart` (export ผ่าน barrel)
- **Sprite rig:** ตัวละครแมวเป็น **layered body-part rig** (head/body/tail/legs แยก layer) ห้าม flatten — รองรับ Mochi Studio (GDD v1.4) และ cosmetic swap
- **ภาษา:** string ทุกตัวผ่าน l10n (TH/EN) ห้าม hardcode
- **Dependency ที่อนุมัติแล้ว:** flame, flutter_riverpod, hive, in_app_purchase, games_services, audioplayers — เพิ่มอื่น = ขอ Opus
- **ห้ามเด็ดขาด:** analytics SDK เก็บ identifier · interstitial/banner ads · network call นอก platform services + ad SDK
- **Ads (v2.0):** rewarded เท่านั้น · SDK ต้องอยู่ในรายการ Google Play Families self-certified ณ วันที่ integrate (Opus เลือก + log DECISIONS) · age band `under13` = non-personalized/child-directed เสมอ · **ไม่ขอ ATT** · ทุกการเรียกผ่าน `AdService` ใน module `ads` เท่านั้น — module อื่นห้าม import SDK ตรง
- **Deterministic sim:** `combat` ใช้ fixed-point + seeded RNG — ห้ามใช้ `double` ใน state ที่มีผลต่อผลแพ้ชนะ, ห้าม `Random()` ไม่มี seed

## 6. Definition of Done (ทุก task)

- [ ] โค้ดอยู่ใน module path ของตัวเอง ไม่แตะไฟล์นอก scope
- [ ] Unit test ครอบ logic หลัก ผ่านทั้งหมด (`flutter test` เขียว)
- [ ] `flutter analyze` = 0 error/warning
- [ ] ถ้าแตะ UI: golden test อัพเดต
- [ ] อ่าน data จาก JSON เท่านั้น ไม่ hardcode content
- [ ] ย้าย task card → `review/` พร้อมสรุป: ทำอะไร / test อะไร / ข้อสังเกต

## 7. Task Card Format (`_dispatch/todo/T-###_module_name.md`)

```markdown
# T-014: combat — dodge & telegraph
Module: combat | Priority: P1 | Depends: T-010
## Goal
implement dodge window + telegraph "!" ตาม GDD §4.1
## Interface (ห้ามเปลี่ยน)
CombatEngine.onTelegraph(Monster m) / PlayerInput.dodge()
## Acceptance
- telegraph นำหน้าโจมตีหนัก 0.8s
- dodge สำเร็จ = invincible 0.5s
- test: timing window ± 1 frame
```

---

*Contract นี้แก้ไขได้โดย Advisor + YK เท่านั้น — ทุกการแก้ bump version + log ลง DECISIONS.md*
