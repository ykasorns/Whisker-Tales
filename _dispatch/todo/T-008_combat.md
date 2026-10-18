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
