# T-027: rig runtime + art integration (P0)
Module: rig | Priority: P0 | Owner: Sonnet | Depends: T-001,T-046
> D-004 · spec: GDD v0.5 · contract v2.1

## Goal
ระบบ rig ใน Flame ตาม GDD v0.5 §2: โหลดชิ้นส่วน 10 ชิ้น + pivot + attach point + animation keyframe จาก JSON (ผลจากต้นแบบ T-046) · ติดชิ้นอุปกรณ์ตามหน้าตาที่เลือก (`wardrobe`) · animation: ยืน, เดิน, ตี 4 แบบตามคลาส, ร่ายสกิล, หลบ, เจ็บ, ชนะ, นอน · มอน/บอสยังใช้ frame animation (sprite sheet)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
RigComponent(rigDef, animations) / play(animId) / setAttachment(slotId, styleId|null) · Flame component ไม่มี game logic

## Acceptance Criteria
- [ ] ประกอบโมจิจากชิ้นส่วนได้ตรงกับภาพอ้างอิง (golden test)
- [ ] เปลี่ยนอุปกรณ์ทุกช่องได้โดยไม่ต้องสร้าง component ใหม่
- [ ] 60 fps บนเครื่อง Android ระดับกลาง ขณะมีโมจิ + มอน 3 + เพื่อนสัตว์ 3
- [ ] rig/animation ทั้งหมดเป็น data (JSON) — เพิ่มท่าใหม่ไม่ต้องแก้โค้ด
- [ ] ไม่มี import ข้าม module (render อย่างเดียว อ่าน state ผ่าน provider)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
