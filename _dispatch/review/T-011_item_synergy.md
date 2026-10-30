# T-011: synergy resolver
Module: item_synergy | Priority: P1 | Owner: Sonnet | Depends: T-010

## Goal
ตรวจคู่ synergy จาก relics.json แล้ว activate combo effect + emit event ให้ UI แสดงเส้นเชื่อม

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
SynergyResolver.activePairs / Stream<SynergyActivated>

## Acceptance Criteria
- [ ] 3 คู่ตัวอย่างใน GDD §6.2 ทำงานครบ
- [ ] ถอด relic (อนาคต) แล้ว combo ดับถูกต้อง

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
synergy = `on_event` ของ buff engine (CONTRACT §4.7) · resolver ทำแค่ตรวจคู่ + emit event ให้ UI · Depends เพิ่ม T-008

---
## ส่งงาน/ตรวจรับ (2026-10-25, D-048)
- [x] `SynergyResolver` คำนวณ `activePairs` จาก relic ที่ถือจริง และ emit `SynergyActivated` เฉพาะคู่ที่เพิ่งติด
- [x] สามคู่ตัวอย่างใน GDD ทำงานครบ: ขนไฟฟ้า+กระดิ่ง, ปลาย่าง+ผ้าพันคอ, กรงเล็บเงา+นมสายฟ้า
- [x] ถอด relic แล้วคู่หายทันที; ใส่ชิ้นเดิมซ้ำไม่ emit ซ้ำ
- [x] resolver ทำเฉพาะตรวจคู่/emit; combo effect ถูก ItemSystem ส่งต่อเข้า BuffEngine
- [x] synergy data ระบุ trigger และ target จึงใช้ extra hit, heal หลัง combat และ crit haste ถูกจังหวะโดยไม่ hardcode คู่ในระบบ
- [x] test ครอบ activation, duplicate, removal และ combo buffs ทั้งสามคู่
