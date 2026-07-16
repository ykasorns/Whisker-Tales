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
