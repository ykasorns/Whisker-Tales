# T-027: avatar — frame animation + gear on anchors (P0)
Module: avatar | Priority: P0 | Owner: Sonnet | Depends: T-001, T-045
> D-005 · spec: GDD v0.5.1 §2, §4 · contract v2.2

## Goal
ตัวละครแมวใน Flame ตามแบบ A + B ที่ทดสอบในเว็บต้นแบบแล้ว: เล่นท่าเต็มตัวตาม skin (ยืน, เดิน 3 วน 1-2-3-2, โจมตีมือเปล่า 5 ตามคลาส, หลบ, เจ็บ, ชนะ, นอน) และวางอุปกรณ์ที่เห็นบนตัว (อาวุธ + โล่/มีดเล่ม 2, หมวก, ผ้าพันคอ, กระเป๋า) ตามจุดยึดต่อเฟรมจาก `design/art/anchors_mochi.json` — ลำดับวาด: กระเป๋า → มีดเล่ม 2 → ตัว → ผ้าพันคอ → หมวก → โล่ → อาวุธหลัก · มอน/บอสใช้ frame animation เดียวกัน (ไม่มีจุดยึด)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
AvatarComponent(skinId, anchors) / play(animId) / setGear(slotId, styleId|null) / setClass(classId) · Flame component ไม่มี game logic

## Acceptance Criteria
- [ ] ตำแหน่ง/มุมอุปกรณ์ตรงกับเว็บต้นแบบทุกเฟรม (golden test 13 เฟรม × 4 คลาส)
- [ ] เปลี่ยน skin / อุปกรณ์ / คลาส ได้ระหว่างเล่นโดยไม่สร้าง component ใหม่
- [ ] อุปกรณ์ 1 ภาพใช้ได้ทุกท่า (grip + size จาก JSON) — เพิ่มแบบใหม่ไม่ต้องแก้โค้ด
- [ ] เท้าอยู่บนเส้นพื้นทุกเฟรม (ใช้ padding ของ slicer ต่อ sheet)
- [ ] 60 fps บนเครื่อง Android ระดับกลาง ขณะมีแมว + มอน 3 + เพื่อนสัตว์ 3

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
