# T-007: combat engine base — deterministic sim + damage pipeline
Module: combat | Priority: P0 | Owner: Sonnet | Depends: T-002,T-003
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
engine สู้ที่ใช้ร่วมทุกโหมด: fixed-point + seeded RNG, stat หลัก/รอง + anti-stat, damage pipeline ตาม GDD v0.4 §4.2, auto-attack ตามความเร็วตี, หลายศัตรู/หลายฝ่าย (แมว + เพื่อนสัตว์ partner damage), PowerScore ตาม §15.2 (ค่าน้ำหนักจาก JSON)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
CombatEngine.start(CombatSetup) / tick(dtMs) / Stream<CombatEvent>
StatBlock (stat+anti-stat, cap จาก data) · PowerScore.of(StatBlock)

## Acceptance Criteria
- [ ] seed เดียวกัน + input เดียวกัน = ผลเหมือนกันทุก event (test 1000 รอบ)
- [ ] ไม่มี `double` ใน state ที่มีผลต่อแพ้ชนะ (fixed-point) · ไม่มี Random() ไม่มี seed
- [ ] สุ่ม hit ครั้งเดียวแบ่ง หลบ/ปกติ/คริ · base = max(ATK−DEF, ATK×floor%) · คริ ×max(1.5, แรงคริ−ลดแรงคริ) · proc = clamp(stat−anti, 0, cap) — ค่าทุกตัวมาจาก data
- [ ] partner (เพื่อนสัตว์) ใช้ช่อง damage แยกได้
- [ ] sim headless 1 คลื่น 5 มอน < 5 ms บนเครื่อง dev (ใช้คำนวณออฟไลน์ได้)
- [ ] มอนแพ้ emit `defeated` (ไม่มี gore)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.1 (D-004, 2026-10-18)
ไม่มี input ผู้เล่นระหว่างสู้ (idle ล้วน) · หลบ = stat (`evade` vs `accuracy`) · ระยะโจมตี melee/ranged ตามคลาส (ranged ตีจากที่ยืน) · ความเร็วตี = `attack_interval_s` ของคลาส × ตัวคูณจาก stat · เพิ่ม stat พิเศษใน `Attribute`: skill_dmg, boss_dmg, pet_dmg, cdr, yarn_find, fish_find, exp_find, craft_luck (GDD v0.5 §5)

---
## ส่งงาน (2026-10-19)
**ไฟล์**
- `packages/wt_core/lib/src/core/contracts/combat.dart` — type ร่วม: `Attribute` (ครบ v0.5 §5 รวม regen + attack_speed), `StatBlock` (int ล้วน, % = basis point), `CombatUnitSpec`, `CombatSetup` (เปลี่ยนจาก abstract เป็น class จริง — ไม่มีผู้ใช้เดิม), event: `HitResolved` `UnitHealed` `UnitStunned` + `UnitDefeated`/`CombatEnded` เพิ่ม `atMs` (named, default 0 — ไม่ทำลายของเดิม) · ทุก event มี value `==`
- `packages/wt_core/lib/src/combat/` — `seeded_rng.dart` (xorshift32), `fixed_point.dart`, `combat_rules.dart` (`CombatRules.fromJson/fromBalance`, รับ key แบบ `ASSUMPTION_` ได้), `combat_engine.dart` (`resolveHit` + `CombatEngine`), `power_score.dart`, `combat.dart` (library)
- `lib/wt_core.dart` export combat · `providers.dart`: `combatRulesProvider` (override ตอน boot) / `combatEngineFactoryProvider` / `powerScoreProvider`
- `design/balance/idle_balance_v1.json` เพิ่ม section `combat` (floor 5%, คริขั้นต่ำ ×1.5, cap ตาม §4.2, น้ำหนัก §15.2 + ASSUMPTION: แรงคริฐาน, cap ดูดเลือด/ฟื้นเลือด/ความเร็วตี/ลดคูลดาวน์, เวลามึน, รอบฟื้นเลือด) — รัน balance sim แล้วผลเดิม (14.8 วัน / 5.8%) PASS

**Test** (`test/combat/`, +34 → รวม 68 เขียว · analyze 0 ทั้ง wt_core / wt_mode_story / app)
- seed เดียวกัน 1000 seed → event เหมือนกันทุกตัว · แบ่ง tick 16/37/120000 ms → ผลเดียวกัน (200 seed)
- resolveHit: floor, ขั้นต่ำ 1, roll เดียวแบ่ง หลบ/คริ/ปกติ, คริ = max(1.5, …), cap ทุกตัว, anti-stat, boss_dmg, pet_dmg เฉพาะช่อง partner
- flow: defeated → ended ครั้งเดียว, แพ้ได้, time limit, attack speed, ลำดับเป้า · partner ไม่โดนตี + ช่องดาเมจแยก · มึน/ดูดเลือด/ฟื้นเลือด/สวน/ตีติด
- RNG ค่าที่รู้ (เทียบกับ Python แยกแล้ว) · PowerScore · perf: 1 คลื่น 5 มอน เฉลี่ย ~0.03 ms (เป้า < 5 ms)

**ข้อสังเกต / หนี้**
- `useSkill(slot)` ยังอยู่ใน interface แต่ขัด D-004 (ไม่มี input ผู้เล่น) → ทำเป็น no-op ไว้ ให้ T-008 ตัดสิน (auto-cast)
- เวลากระโดดจาก action ถึง action (ไม่ใช่ step คงที่) → ลำดับใน ms เดียวกัน: ฟื้นเลือด → ฝั่งแมว → ศัตรู ตามลำดับใน setup
- melee/ranged เก็บไว้ใน spec สำหรับ render เท่านั้น ไม่มีระยะทางใน sim
- ตัวคูณคลาส (`classes`) ไม่อ่านใน combat — `cat_class` (T-044) ส่ง StatBlock + attackIntervalMs สุดท้ายมา · สัดส่วน HP:ATK มอน 60:40 เป็นของ `idle_loop` (T-034)
- T-003 ยังไม่เสร็จ: test อ่าน JSON ตรงจาก `design/balance/` · T-003 ต้องเพิ่ม schema ของ section `combat`
- balance sim ใช้ "พลัง" แบบรวมก้อน ไม่ใช่สูตร §15.2 → ตัวเลขพลังในเกมจะไม่ตรงกับ sim จนกว่า T-029 จะผูก stat จริง
- **หน่วยไม่เหมือนกันในไฟล์เดียว:** `combat` ใช้ % (5 = 5%) แต่ `classes` ใช้เศษส่วน/ตัวคูณ → T-044 แปลง `evade_add` ด้วย ×10000 (0.15 → 1500 bp) และ `skill_dmg` เป็นโบนัส `(mult − 1) × 10000` bp ของ `Attribute.skillDmg` (1.8 → 8000) — ห้ามส่งผ่าน `bpFromPct`
- `HitResolved.damage` = ขนาดฮิตเต็ม (รวม overkill) · ดาเมจที่ทำได้จริง = HP ที่ลด (`damageDealt()`)

---
## ตรวจรับ (2026-10-23, Opus) → done
- ✓ deterministic 1000 seed + แบ่ง tick ต่างกันได้ผลเดิม · ✓ fixed-point/SeededRng (`seeded_rng_test`) · ✓ สูตร hit/คริ/proc จาก data (`resolve_hit_test`, `combat_rules_test`) · ✓ partner channel · ✓ headless 5 มอน < 5 ms · ✓ `UnitDefeated` ไม่มี gore
- หนี้เดิม "T-003 ยังไม่เสร็จ" ปิดแล้ว (อ่านผ่าน ContentRepository)
