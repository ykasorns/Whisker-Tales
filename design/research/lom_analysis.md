# Research — Legend of Mushroom (LoM) Teardown → Whisker Tales

**วันที่:** 2026-10-12 | **เครื่องมือ:** REA 6.4.0 (static) + อ่าน shipped bundle | **สถานะ:** Research note (ไม่ใช่ contract)
**คำถามตั้งต้น (YK):** วิเคราะห์ LoM แล้วนำมาปรับใช้กับ Whisker Tales โดยใช้แมวแทนน้องเห็ด → ทิศทางที่เลือก: **เปลี่ยนเป็น idle RPG** (ดูข้อเสนอใน `_contract/GDD_WhiskerTales_v0.4.md`)
**ระบบที่ขอให้เจาะ:** Equip loop · Buff/Skill engine · Pet + Science · Rogue mode

---

## 0. ขอบเขตและกติกาที่ใช้วิเคราะห์

| หัวข้อ | สิ่งที่ทำ / ไม่ทำ |
|---|---|
| วิธี | **Static เท่านั้น** — อ่านไฟล์ที่ติดมากับแอป ไม่ได้รันเกม ไม่ได้ดักทราฟฟิก ไม่ได้ส่งอะไรไปเซิร์ฟเวอร์เขา |
| Native binary | เข้ารหัส FairPlay (`cryptid 1`) → **ไม่ถอด** (เลี่ยง DRM) — ไม่จำเป็น เพราะ game logic เป็น JS |
| ตารางค่า config | เก็บเป็น binary XOR+compressed → **ไม่ถอด** อ่านแค่ **schema (ชื่อฟิลด์)** จากคลาส accessor ฝั่ง client |
| IP | บันทึกเฉพาะ *กลไก / รูปทรงสูตร / สถาปัตยกรรม* ด้วยคำของเราเอง — **ไม่คัดลอกโค้ด ตารางค่า ตัวเลขบาลานซ์ ชื่อ asset หรือภาพ** |
| เวอร์ชัน | วิเคราะห์ bundle ที่ติดมากับแอป v2.0.34 — เกมมี hot-update (`main.js` อ่าน search path จาก localStorage) โค้ดที่รันจริงอาจใหม่กว่านี้ **ยังไม่ได้ตรวจ hot-update cache** |

**ระดับความเชื่อมั่นที่ใช้:** `observed` = เห็นตรงในโค้ด/schema · `inferred` = อนุมานจากชื่อฟิลด์/ข้อความ · `unknown` = ตอบไม่ได้จาก static

---

## 1. ตัวตนของเป้าหมาย

| รายการ | ค่า |
|---|---|
| Path | `/Applications/Legend of Mushroom.app/Wrapper/carDemo-mobile.app` (iOS app รันบน Apple Silicon) |
| Bundle id / version | `com.mxdzz.ios.sea` / 2.0.34 |
| Engine | Cocos Creator 3.x (`src/cocos-js/cc.js`, `assets/*/index.js`, `jsb-adapter`) |
| Game script | `assets/script/index.js` — 21 MB, **4,549 modules** (ชื่อ `.ts` เดิมยังอยู่) — sha256 `76a65074…8180c6` |
| Config tables | **710** โมดูล `Config*.ts` (schema 704 ตารางที่ parse ได้) |
| REA evidence | app-level summary: `ev_2080cfc04a929009e0c89c5abd9f4708a5d2ad67e643e3df812c17454c05198a` (partial — `index.js` timeout 300 s; ad-SDK JS หมด heap) / view `ev_703f647552f6cb8d0dd052f54bb0c74281348ea8072726a387435f5e38b316dc` |

> ⚠️ REA full semantic graph ของ `index.js` ยังไม่สมบูรณ์ (ดู F14) — ผลด้านล่างส่วนใหญ่มาจากการอ่าน module ทีละไฟล์ (split ตาม `System.register`) ซึ่งเป็น static text inspection ของ artifact เดียวกัน

---

## 2. สถาปัตยกรรมภาพรวม (observed)

- **Server-authoritative**: ทุกระบบเป็นคู่ `XxxControl` (ส่ง/รับ `netManager` message `xxx.yyy_c2s` / `_s2c`) + `XxxModel`/`XxxDataCache` (state ฝั่ง client) + `XxxDefine` (enum/event) + `XxxView` (UI) — ผลสุ่มทุกอย่าง (เปิดกล่อง, draw) **เกิดที่ server** client แค่แสดงผล
- **Battle sim deterministic**: ใช้ `FixMath` (fixed-point) + `battleMain.random` (seeded) + มีคู่ไฟล์ `*CC.ts` / `*Server.ts` ต่อ chapter → inferred: sim ชุดเดียวรันได้ทั้ง client (แสดงผล) และ server (ตรวจผล/คำนวณ offline)
- **Data-driven ทั้งเกม**: 704 ตาราง config อ่านผ่าน `BaseConfig` (index ตาม `mainKey`, deep-freeze) — เพิ่ม content ไม่แตะโค้ด (ตรงหลัก GDD §13 ของเราอยู่แล้ว)
- **ขนาดระบบ**: 152 โมดูล `*Control.ts` — ในนี้ 66 เป็น *Activity* ตามเทศกาล/collab, มี PvP/Guild/Chat/Friend/Marry/Mall/Pay/Ad/BattlePass/Privilege/Draw — ส่วนใหญ่เป็น live-ops + monetization

---

## 3. Equip Loop — หัวใจของ LoM

### 3.1 Flow (observed — `EquipControl.ts`, `EquipModel.ts`, `EquipDefine.ts`)
```
ใช้ "ตั๋วเปิดกล่อง" 1 ใบ → equip_box_open_c2s → server สุ่ม 1 ชิ้น
  → client เปิด EquipEditView: เทียบกับของที่ใส่อยู่ในช่องเดียวกัน
  → ผู้เล่นเลือก: สวม (wear) หรือ ขาย (shop → ได้ reward คืน)
เปิดหลายใบ: equip_box_open_all_c2s {num, quality} — ผลเรียงตาม quality > level
```
- **Auto-open** (observed): ตั้งเงื่อนไข = quality ขั้นต่ำ + เงื่อนไข affix ได้ 2 ชุด (ชุดละ ≤2 affix ที่ต้องมี) → ชิ้นที่ไม่ผ่าน **ขายอัตโนมัติ**, ชิ้นที่ผ่านหยุดให้ผู้เล่นตัดสิน; หยุดเองเมื่อตั๋วหมด
- **"ดีกว่า" = ครอบงำทุก base stat** (observed `checkIsBetterEquip`): ของใหม่ดีกว่าก็ต่อเมื่อ base attr ทุกตัว ≥ ของเดิม และไม่เท่ากันทั้งหมด → ใช้ทำ red-dot/ลูกศรเขียว
- **Offline open** (observed): `equip_offline_open_box_setting_c2s {quality, attr_condition_list, open_num, is_offline_open}` → เปิดกล่องต่อขณะออฟไลน์ด้วยเงื่อนไขเดียวกัน
- **Temp bag** (observed `EquipTempBagView`, `getEmptyEquipIdList`): ของที่ยังไม่ตัดสินใจพักไว้ ต้องเคลียร์ก่อนเปิดใหม่

### 3.2 Progression รอบกล่อง (schema — observed field names)
| ตาราง | ฟิลด์ | ความหมาย (inferred) |
|---|---|---|
| `Equipment` | level, part, quality, advanced, suitId, job, gradeRange, preAttr, is_precious, unlock_level | ชิ้น = (ช่อง × ระดับ × เกรด) ผูกสาย job ได้ มีชุด set |
| `Equipment_attr` | group_id, attr_id, type, pro, value | pool ของ random affix แบบถ่วงน้ำหนัก (`pro`) |
| `Equipment_level` | part, level, basic, price | base stat + ราคาขาย ต่อ ช่อง×เลเวล |
| `Equipment_guarantee` | num, quality, level, part | **pity**: ครบ N ครั้งการันตีเกรด |
| `Equipment_refinement` / `_resonance` / `_advancement` / `_suit` | … | sink ระยะยาว: ตีบวกตาม "ช่อง" (ไม่ผูกชิ้น), resonance เมื่อทุกช่องถึงขั้น, set bonus |
| `EquipDefine.EquipQuality` | 11 ขั้น (WHITE→FOREVER) | เกรดสีขยายตามซีซัน |
| `BoxChangeType` | lvUp, expAdd | **กล่องมีเลเวล/EXP** — เปิดบ่อย → กล่องเลเวลขึ้น → (inferred) โอกาสเกรดสูงขึ้น |

**Insight ออกแบบ:** วงจร *เปิด→เทียบ→สวม/ขาย* ใช้เวลา 2 วิ ให้ dopamine ถี่มาก และ **refinement ผูกกับช่อง ไม่ผูกกับชิ้น** ทำให้เปลี่ยนของใหม่ได้โดยไม่เสียการลงทุน — ตัดความลังเลออกจาก loop

---

## 4. Combat / Buff / Skill Engine

### 4.1 Damage pipeline (observed — `HurtUtil.ts`; รูปทรงสูตร ไม่ใช่ค่าตัวเลข)
1. **Hit table รอบเดียว**: สุ่ม 0–10000 ครั้งเดียวแบ่งช่วง *miss / normal / crit* — miss มาจาก `max(miss − hit, 0)` ผ่าน curve แก้; crit มาจาก `max(crit_rate − ignore_crit_rate, 0)`
2. **Base**: `max(ATK − DEF × (1 + def_coe), 1)` → DEF แบบ*ลบ* แต่มี floor = 1
3. **ตัวคูณ**: × dmg_bonus × (1 − resist) × penetrate mod (เกินฝั่งรับ → +เชิงเส้น, ต่ำกว่า → ลดแบบ exponential) × pve_dmg × (1 − pve_resist), floor 1
4. **Crit mult** = `max(1.5, crit_dmg / crit_def)`
5. **Proc แยก**: combo (double_hit), counter, knock-up (suspend), stun, lifesteal — ทุกตัวเป็นคู่ **stat ↔ anti-stat** (`double_hit` vs `ignore_double_hit` ฯลฯ) prob = `max(stat − anti, 0)` เป็น basis point
6. **Cap ต่อ attribute** ผ่านตาราง `Attribute.up_limit` + `num_type` (int vs ‱)

**Insight:** ความลึกของ stat มาจาก *คู่ stat/anti-stat* — เพิ่ม stat ใหม่ = เพิ่ม 2 แถวใน `Attribute` ไม่ต้องแก้สูตร

### 4.2 Buff engine (observed — `Buff.ts`, `BuffCtr.ts`, `BuffAttrib.ts`, `BuffShield.ts`; 85 โมดูล `Buff*`)
- `Buff` base class มี **hook** ครบ: `onBegin/onDestroy/onUpdate/onDamage/onTotalDamage/onStateTrigger/onAddBuffTrigger/onCalHeal/onCalHpDamage/onShieldAction/onShareDamageAction/checkSkillReturn/getFixTime` — subclass override แค่ hook ที่ใช้
- ตาราง `Buff`: `type, group, mutex, add_max, bind, action, param1..param5` → **`action` (string) เลือก subclass**, param เป็น payload — เช่น `attrib` (param1=attr id, param2=บวก/คูณ, param3=ค่า), `shield` (คำนวณจาก ATK−DEF / HP ที่หาย / HP ปัจจุบัน แล้ว chain buff เริ่ม/จบ ผ่าน param5)
- **State triggers**: buff ประเภท STATE_TRIGER ฟัง event (`Shield`, `Shield_End`, ฯลฯ) แล้วยิง buff อื่นต่อ → combo/synergy ทั้งหมดเป็น *data*
- Object pool ต่อ subclass (`ObjectPool(cls, 30)`) + fixed-point → ไม่สร้าง garbage ระหว่างสู้
- ตัวอย่างชนิด (ชื่อโมดูล): DoubleDamage, ResetCd, PauseCd, Vampire, Taunt, Trap, TimeReversal, GiantSlayer, ImmuneDeath, ShareDamage, DeferDamage, RandomSkillTrigger, CallUnit/CallSpirit …

### 4.3 Skill (schema — observed)
- `Skill`: quality, buffGroup, addSkill, releaseTime/Interval, targetType/Range, skillEffect1/2, skillPar, initial/max/recoveryPower … → สกิล = กลุ่ม buff + การเล็งเป้า + cooldown
- `Skilleffcet` (สะกดตามต้นฉบับ): trap, bullet, buffGroup + buffRate, randomType → effect เป็น data ทั้งหมด
- `Skill_level`: `ownEffect` (passive ตอนมีในคลัง) + `skillCoefficient` → **สกิลให้ stat แม้ไม่ได้ใส่ช่อง** = แรงจูงใจสะสม
- `Skill_pos`: ช่องสกิลปลดล็อกตามเงื่อนไข · ได้สกิลจาก **Draw (gacha)** → ❌ ไม่ใช้

---

## 5. Pet + Science

### 5.1 Pet (observed schema + `PetControl.ts`)
- `Pet`: quality, type, unitId, talent, power · `Petlevel`: `ownEffect` (passive ตอนครอบครอง) + `equipEffect` (ตอนออกรบ) + stat ต่อสู้ของตัวเอง (att_range, att_speed, crit, double_hit, stun ฯลฯ)
- `Pet_pos`: ช่องออกรบปลดล็อกตามเงื่อนไข · `Pet_talent`: talent ตามจำนวนดาวรวม · `Pet_proficiency`: ความชำนาญเพิ่ม star
- ดาเมจ partner ใช้สูตรแยก (`partner_dam`, `partner_resist`, `partner_penetrate`) → pet เป็น *unit จริง* ในสนาม ไม่ใช่แค่ buff
- message: `pet_levup`, `pet_set_pos`, `pet_set_all_pos`, preset tab (`pet_choose_tab`) · ได้ pet จาก draw → ❌

### 5.2 Science (observed schema + `ScienceControl.ts`)
- `Science`: level, type, **time**, cost, condition, attr, skill, power → research tree แบบ**ใช้เวลาจริง** มี prerequisite ปลดล็อกทั้ง stat และ *ฟีเจอร์/สกิล*
- `science_worker_setting_c2s {team, auto_time, science_list}` → มี "ทีมคนงาน" ตั้งคิววิจัยอัตโนมัติ
- unknown: เร่งเวลาด้วยเงินจริงหรือไม่ (ไม่พบใน control นี้ — อาจอยู่ใน item/privilege)

---

## 6. Rogue Mode (observed — `RogueControl.ts` messages + schema)
```
rogue_main_enter → (start_reward_info/refresh/confirm: เลือกของเริ่ม run, รีเฟรชได้)
  → main path: main_combat → main_result
      ↳ branch: branch_type → enter → meet / enemy / shop(buy) / combat → result → exit
  → attr_up (อัพ stat ใน run), copy_skill (คัดลอกสกิล), set_skill
  → main_over → weekly ranking / reports
meta: rogue_science_research / reset (tree ถาวรของโหมด, รีเซ็ตได้)
```
- ตาราง: `Rogue_main_chapter` (enemy multiplier, this_reward / **this_punishment**, next_starting, end_reward, point), `Rogue_goods` (quality, uniqueness, **loseable**), `Rogue_goods_mall` (weight แยก sidestory/boss), `Rogue_gift` (node_type, condition, cost, special_effect), `Rogue_sidestory_*`
- `Rogue_draw` / `truntable` = กงล้อสุ่ม → ❌
- **Insight:** โครงนี้ใกล้ Story mode ของ Whisker Tales v0.3 มาก (node map + shop + event + boss + meta tree) → **ไม่ต้องทิ้งงาน roguelite เดิม** ย้ายไปเป็นโหมดเสริมได้ตรง ๆ

---

## 7. สิ่งที่ "ไม่เอา" และเหตุผล (ขัด GDD §12 / rating 4+)

| ระบบ LoM | ปัญหา | ทางแทน (ดู GDD v0.4 draft) |
|---|---|---|
| Draw / Spirit_draw / Rogue_draw / Roulette / turntable | loot box + gacha | ปลดล็อกแบบ deterministic (milestone, สมุดสะสม, ร้านปลาทอง) |
| Ad, FloatAD, Ads_reward, Chapter_type.ad | ads ทุกชนิดห้าม | ไม่มี — รางวัล offline ไม่มีปุ่ม "ดูโฆษณา x2" |
| Pay, Mall, Privilege, WeeklyCard, AccRecharge, BattlePass (paid) | pay-to-win / dark pattern | IAP cosmetic เท่านั้น |
| PvP, Guild, Chat, Friend, Marry, CrossWar | social/UGC ในเกมเด็ก | ไม่มีในแผน |
| ตั๋วเปิดกล่อง/ตั๋ว challenge ที่ซื้อได้ | energy-like gating | ทรัพยากรได้จากการเล่นเท่านั้น ไม่ขาย |
| 66 Activity เทศกาล | FOMO + ต้นทุน live-ops สูง | `activities.json` ชั้น 3 (MODE_PLUGIN_SPEC) แบบเบา ไม่มี paid tier |

---

## 8. Finding ledger

| # | ข้อสรุป | ระดับ | หลักฐาน |
|---|---|---|---|
| F1 | game logic = Cocos JS, native ถูกเข้ารหัส | observed | `otool` LC_ENCRYPTION_INFO_64 cryptid 1; `assets/script/index.js` |
| F2 | ผลสุ่มอุปกรณ์อยู่ที่ server | observed | `EquipControl.ts` (`equip_box_open_c2s` → `_s2c.equip_id`) |
| F3 | auto-open: quality + 2×affix set, ไม่ผ่าน=ขาย | observed | `EquipModel.ts` `checkEquipIsConditionOk`, `doAfterOpenBox` |
| F4 | "ดีกว่า" = dominate ทุก base stat | observed | `EquipModel.ts` `checkIsBetterEquip` |
| F5 | กล่องมี level/exp, มี pity | observed (field) / inferred (ผล) | `EquipDefine.BoxChangeType`; schema `Equipment_guarantee` |
| F6 | DEF แบบลบ floor 1, crit ≥1.5×, proc = stat−anti | observed | `HurtUtil.ts` `normalHurt`, `checkHit`, `checkDoubleAct` |
| F7 | battle sim deterministic, client+server | observed (FixMath, seeded RNG) / inferred (server replay) | `HurtUtil.ts`, `Buff.ts`; คู่ไฟล์ `Chapter*CC.ts`/`*Server.ts` |
| F8 | buff = action string + params + hooks + state triggers | observed | `Buff.ts`, `BuffAttrib.ts`, `BuffShield.ts`; schema `Buff` |
| F9 | สกิล/pet ให้ passive ตอน "ครอบครอง" | observed (field) | schema `Skill_level.ownEffect`, `Petlevel.ownEffect` |
| F10 | science ใช้เวลาจริง + คิวอัตโนมัติ | observed | schema `Science.time`; `science_worker_setting_c2s` |
| F11 | Rogue = main path + branch + shop + meta tree + weekly rank | observed | `RogueControl.ts` messages; schema `Rogue_*` |
| F12 | ตัวเลขบาลานซ์จริงทั้งหมด | **unknown (ตั้งใจไม่ถอด)** | config เป็น XOR+compressed binary |
| F13 | โค้ด hot-update ล่าสุดต่างจาก bundle นี้แค่ไหน | **unknown** | `main.js` search-path จาก localStorage; cache ยังไม่ได้ตรวจ |
| F14 | REA semantic graph เต็มของ index.js | **partial** | รอบ 1 `ev_2080cfc0…` timeout 300 s · รอบ 2 (CLI, heap 8 GB, timeout 30 นาที) `ev_a0eb4a5be95b9b357390cc8cd24d71201009a0e69aba094217cf909cd5600b85` จบใน ~6 นาที แต่ยัง partial: facts เกิน transfer budget และ REA 6.4.0 ไม่รู้จัก module แบบ SystemJS (`modules: 0`) → ใช้วิธีแยก module ตาม `System.register` แล้วอ่านทีละไฟล์แทน |
