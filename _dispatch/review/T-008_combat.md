# T-008: buff engine + skills + cooldown
Module: combat | Priority: P0 | Owner: Sonnet | Depends: T-007
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
buff engine ตาม CONTRACT §4.7: action → class ที่ override hook, state events (`crit`, `dodge`, `shield_break`, `kill`, `wave_start`, `skill_cast`) ยิง buff ต่อผ่าน `on_event`, mutex/stack_max, object pool · สกิลแมว 3 ช่อง = กลุ่ม buff + เป้า + cooldown, auto-cast + แตะเองได้ · โหลด relic/talent `effects[]` เป็น buff id ได้

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
BuffEngine.apply(unit, buffId, source) / CombatEngine.useSkill(slotIndex) / SkillLoadout

## Acceptance Criteria
- [ ] action ขั้นต่ำ: `attrib` (บวก/คูณ), `shield`, `dot`, `stun`, `cooldown_mod`, `extra_hit`, `heal`, `add_buff`
- [ ] buff ใหม่จาก JSON โดยไม่แก้โค้ด (test: เพิ่ม buff ใน fixture แล้วทำงาน)
- [ ] on_event chain ลึก ≥3 ชั้น + กัน loop ไม่รู้จบ (depth cap)
- [ ] ไม่มี allocation ใหม่ระหว่าง tick หลัง warm-up (pool) — วัดใน test
- [ ] กดสกิลตอน cooldown = ไม่มีผล ไม่ crash · auto-cast ทำงานเมื่อไม่มีการแตะ
- [ ] relic 'ขนแมวไฟฟ้า' + 'กระดิ่งสะท้อน' (fixture) ทำ synergy ผ่าน on_event ได้

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.1 (D-004, 2026-10-18)
สกิลเปลี่ยนเป็น **สกิลคลาส** (GDD v0.5 §3.2): 4 คลาส × 3 = 12 สกิล **ร่ายเองตาม cooldown เท่านั้น** (ตัด `useSkill(slotIndex)` จากการแตะ — เก็บเป็น API ภายในให้ auto-cast เรียก) · ช่องสกิลปลดตามเลเวลจาก `cat_class` · เมจ: cooldown ×0.75 + ดาเมจสกิล ×1.8 จาก JSON · Depends เพิ่ม T-044

---
## ส่งงาน (2026-10-19)
**ไฟล์**
- `core/contracts/combat.dart` — `SkillSpec`, `SkillTarget`, `CombatUnitSpec.skills` + `copyWith`, `AttackSource.skill/dot/extra`, event ใหม่ `SkillCast` `BuffApplied` `BuffEnded` `ShieldAbsorbed`
- `src/combat/buffs.dart` — `BuffBook.fromJson` (action ครบ: attrib/shield/dot/stun/cooldown_mod/extra_hit/heal/add_buff · group/mutex/stack_max · on_event · ตรวจ id ที่อ้าง), `SkillBook.fromJson` (คลาสละ 3 ตามช่อง)
- `src/combat/combat_engine.dart` — สกิล/บัฟ/โล่/dot อยู่ในไทม์ไลน์เดียวกัน (ยังแบ่ง tick ยังไงก็ผลเดิม) · ค่าพลังจริงรวมบัฟ (`statsOf`) · `CombatEngine` เป็น `IBuffEngine` ด้วย (`apply`) · `useSkill` = ร่ายถ้าพร้อม (ภายใน)
- `src/cat/cat_class.dart` — `combatSpec` ใส่สกิลตามช่องที่ปลด (inject `skillsFor`, ไม่ import combat)
- `src/idle/road_events.dart` — ใช้ `copyWith` (สกิลไม่หายเมื่อมีผลเหตุการณ์)
- providers: `buffBookProvider`, `skillBookProvider` (ค่าว่างจนกว่าจะโหลด), engine factory ใช้บัฟ + first cast
- `design/data/buffs.json`, `design/data/skills.json` (ใหม่) — 12 สกิล + 11 บัฟ

**Test** (+15 → รวม 177 · analyze 0 ทั้ง 3 package)
- ข้อมูล + validator · ร่ายตาม cooldown (ครั้งแรก 50%, cdr) · หลบสกิลไม่ได้ · skill_dmg/คริ · AoE โดนทุกตัว · ติดมึนแล้วรอ · useSkill ตอน cooldown ไม่มีผล
- โล่ดูดก่อนแล้วแตก (ดาเมจที่ดูดไม่นับเป็นดาเมจที่ทำ) · พิษซ้อน 3 ชั้น · บัฟค่าพลังแล้วหมดอายุ · **บัฟใหม่จาก JSON อย่างเดียว** · on_event ลึก 3 ชั้น + loop A↔B หยุดที่ depth cap · relic fixture ขนแมวไฟฟ้า + กระดิ่งสะท้อน ทำ synergy ได้
- แบ่ง tick 16/37/120000 ms ผลเดิม — ทุกคลาส ครบ 3 สกิล, 40 seed
- T-044: เมจทำดาเมจสกิลมากที่สุด (sim จริง แทนการเช็กแค่ตัวคูณ) · โจรนับเฉพาะตีปกติ · สกิลปลดตาม Lv10/20/30

**วัดผล (4 มอน, อุปกรณ์เท่ากัน, 50 seed — เวลาเคลียร์คลื่น)**
| | นักรบ | โจร | ธนู | เมจ |
|---|---|---|---|---|
| Lv10 (สกิล 1) | 24.0 วิ | 16.8 | **12.0** | 14.0 (สกิล 64%) |
| Lv30 (สกิล 3) | 27.0 | 18.3 | 11.0 | **7.9** (สกิล 84%) |
- จูนแล้ว: ลูกไฟ cd 4→3 วิ · วงน้ำแข็ง 140→110% · อุกกาบาต 320→240% (เดิม Lv30 เมจ 4.5 วิ แรงเกิน)

**ข้อสังเกต / หนี้**
- AC "ไม่มี allocation ระหว่าง tick (pool)" **ตรวจใน unit test ไม่ได้** (Dart ไม่มีตัวนับ allocation) — ใช้ list ต่อยูนิต + ไม่สร้าง object ต่อ tick ยกเว้น event/บัฟใหม่ · ถ้าต้องวัดจริงใช้ DevTools memory profile
- attack speed จากบัฟมีผลตั้งแต่การตีครั้งถัดไป (ครั้งที่จองไว้แล้วเวลาเดิม)
- PowerScore ไม่นับสกิล → 🐾 ของเมจดูต่ำกว่าความแรงจริง · balance sim ไม่จำลองสกิล → ส่ง T-029
- ต้นแบบ v15: แถบสกิลมุมซ้ายล่าง (วงคูลดาวน์) + ชื่อสกิลลอย + ลูกไฟ/วงน้ำแข็ง/อุกกาบาต/โล่/💫
