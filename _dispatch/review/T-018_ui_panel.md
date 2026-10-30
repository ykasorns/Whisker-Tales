# T-018: card pick panel (relic+talent)
Module: ui_panel | Priority: P1 | Owner: Sonnet | Depends: T-014,T-011,T-012

## Goal
การ์ด 3 ใบเต็มโซน, เส้นประดินสอเชื่อม synergy, พื้นหลังการ์ด talent ตามสี tree (Coral/Plum/Teal)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
CardPickPanel(List<Pickable>) -> Future<Pickable>

## Acceptance Criteria
- [x] เส้น synergy โผล่เฉพาะคู่ที่ combo จริง
- [x] แตะพลาดไม่ confirm ทันที (แตะการ์ด = ขยาย, แตะซ้ำ = เลือก)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## Delivery summary (2026-10-25)

- เพิ่มการ์ด Relic/Talent 3 ใบเต็มแผง พร้อมสี Coral/Plum/Teal ตามสาย Talent
- แตะครั้งแรกขยายคำอธิบายและเลือกสถานะ; แตะใบเดิมครั้งที่สองจึงยืนยัน
- เส้นประดินสอและสายฟ้าแสดงเฉพาะเมื่อ Relic/Talent ที่ถืออยู่เกิด synergy จริง

### Verification

- Widget test ครอบ two-tap และ electric_fur × Magic T3 synergy
- Golden relic/talent panels ผ่าน
