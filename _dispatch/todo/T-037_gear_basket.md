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
