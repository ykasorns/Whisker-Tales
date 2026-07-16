# GAME_CONTRACT.md — Whisker Tales 🐱📖

**Version:** 1.2 | **อ้างอิง:** GDD_WhiskerTales_v0.3.md + MODE_PLUGIN_SPEC.md
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
│   ├── GDD_WhiskerTales_v0.3.md
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
| `combat` | `packages/wt_core/lib/src/combat/` | auto-attack, skill, dodge/telegraph, ผลลัพธ์สู้ | core |
| `item_synergy` | `packages/wt_core/lib/src/items/` | relic/potion, synergy resolver (อ่าน relics.json) | core, combat |
| `talent_system` | `packages/wt_core/lib/src/talents/` | XP/level, talent pick, effect resolver (อ่าน talents.json) | core, combat |
| `meta_progression` | `packages/wt_core/lib/src/meta/` | หมู่บ้าน, ปลดล็อก, currency ถาวร | core, save |
| `ui_panel` | `packages/wt_core/lib/src/ui/` | โซนล่าง 40% ทุก state + HUD + node map ลอย | ทุก module ผ่าน Riverpod provider เท่านั้น |
| `save_cloud` | `packages/wt_core/lib/src/save/` | local (Hive) + cloud sync (Game Center/Play Games), versioned save schema | core |
| `audio` | `packages/wt_core/lib/src/audio/` | BGM/SFX service | core |
| `iap_gate` | `packages/wt_core/lib/src/iap/` | in_app_purchase + parental gate | meta, save |

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

### 4.5 Effect Vocabulary
`trigger`: `passive | on_attack | on_crit | on_dodge | on_skill | on_combat_end | on_level_up`
`action`: `stat_mod | spawn_spark | spark_chain | heal | speed_buff | counter | cooldown_mod | star_bomb` — เพิ่ม action ใหม่ = แก้ resolver ใน module เดียว + ขอ Opus อนุมัติ

---

## 5. Technical Standards

- **Flutter 3.x + Flame** (เวอร์ชันล็อกใน pubspec — Sonnet ห้ามอัพเกรด)
- **State:** Riverpod เท่านั้น — ห้าม setState ข้าม widget, ห้าม global mutable
- **Layout:** `GameWidget` (Flame) สูง 60% ของ safe area / Flutter UI panel 40% — ratio เป็น constant ใน `packages/wt_core/lib/src/core/layout.dart` (export ผ่าน barrel)
- **Sprite rig:** ตัวละครแมวเป็น **layered body-part rig** (head/body/tail/legs แยก layer) ห้าม flatten — รองรับ Mochi Studio (GDD v1.4) และ cosmetic swap
- **ภาษา:** string ทุกตัวผ่าน l10n (TH/EN) ห้าม hardcode
- **Dependency ที่อนุมัติแล้ว:** flame, flutter_riverpod, hive, in_app_purchase, games_services, audioplayers — เพิ่มอื่น = ขอ Opus
- **ห้ามเด็ดขาด:** analytics SDK เก็บ identifier, ads SDK, network call นอก platform services

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
