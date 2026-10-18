# T-032: endless mode vertical slice (พิสูจน์ plugin architecture)
Module: mode_endless | Priority: P1 | Owner: Sonnet | Depends: T-031

## Goal
สร้าง `wt_mode_endless` — ตะลุยไร้จุดจบ: EncounterSource แบบ infinite, ความยาก f(depth) เพิ่มเชิงเส้น+ขั้นบันได, mini-boss ทุก 10 depth, best_depth ใน save, การ์ด hub โชว์สถิติ — ตาม MODE_PLUGIN_SPEC §6 (ship แบบ enabled:false ใน MVP, เปิดจริง v1.2)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
implements GameMode เท่านั้น — import ได้เฉพาะ package:wt_core/wt_core.dart

## Acceptance Criteria
- [ ] ★ จำนวนไฟล์ที่แก้ใน wt_core = 0 (นี่คือ acceptance หลักของสถาปัตยกรรม)
- [ ] ผ่าน ModeConformanceTest
- [ ] next() ทำงานถึง depth 1000 ใน test โดย memory คงที่ (ไม่สะสม node list)
- [ ] unlock condition: story_boss1_cleared ทำงานผ่าน manifest
- [ ] enabled:false → ไม่โผล่ใน hub / เปิด flag → โผล่พร้อมการ์ดล็อก/ปลดล็อกถูกต้อง

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
คงไว้ **P2 dormant** — ต่างจากโหมดหลัก idle ตรงที่เป็น run จบด้วยการตาย ใช้ relic/talent · ยังเป็น acceptance พิสูจน์ plugin (แก้ core = 0) · ถ้า Opus เห็นว่าทับซ้อน ให้เสนอ drop ผ่าน DECISIONS

---
## Amendment v2.1 (D-004, 2026-10-18)
โหมดเสริมแบบ run ตอนนี้มี: ท้าทายนิทาน (story) + ดันเจี้ยน (T-047, v1.1) — endless ยังคง P2 dormant
