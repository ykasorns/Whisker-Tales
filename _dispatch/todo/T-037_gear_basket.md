# T-037: auto-craft
Module: gear_basket | Priority: P1 | Owner: Sonnet | Depends: T-036
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
auto-craft GDD v0.4 §3: ตั้งช่อง (วนหลายช่อง) + เกรดขั้นต่ำ + affix ≤2 → ไม่ผ่านรีไซเคิลเอง, ผ่าน/ดีกว่าแน่นอนหยุดรอผู้เล่น · ทำงานเฉพาะตอนเปิดเกม · หยุดเมื่อไหมพรมหมด

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
AutoCraft.configure(AutoCraftRule) / start() / stop() / Stream<AutoCraftStopped(reason)>

## Acceptance Criteria
- [ ] ไม่รีไซเคิลของที่ isStrictlyBetter เด็ดขาด
- [ ] ไม่ทำงานระหว่างออฟไลน์
- [ ] rule บันทึกใน save และโหลดคืนได้

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.1 (D-004, 2026-10-18)
เปลี่ยนตาม GDD v0.5 §4.3: เปิด/ปิด + โหมด `stash` (เก็บรอเลือก ช่องละ 1 ชิ้นที่ดีที่สุด) / `equip` (ใส่ทันที) · ถักช่องที่อ่อนที่สุด (นับทั้งของใส่และของรอ) · ของอ่อนกว่ารีไซเคิลเอง · ตัดเงื่อนไข min_grade/affix ออกจาก MVP · ต้นแบบอ้างอิง: เว็บต้นแบบ (autoCraftOnce)
