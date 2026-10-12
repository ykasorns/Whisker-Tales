# T-038: pets — roster, stars, deploy, hatch + daily quota + pity
Module: pets | Priority: P0 | Owner: Sonnet | Depends: T-007,T-033,T-039
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
เพื่อนสัตว์ GDD v0.4 §6: roster 6 ตัว, ดาว 1–5 จากตัวซ้ำ, ช่องออกรบตามบท, passive ตอนครอบครอง · ฟักไข่: ไข่ที่มี / ad (ผ่าน AdService) / ปลาทอง 5 ครั้ง/วัน ราคา ×1.5 · อัตรา + pity จาก JSON

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
Pets.hatch(source: egg|ad|fish) -> HatchResult / nextFishCost / quotaToday / rates (UI) / deploy(slot, petId)

## Acceptance Criteria
- [ ] อัตราตรง JSON (chi-square) + pity ตำนานไม่รีเซ็ตข้ามวัน
- [ ] quota ปลาทองรีเซ็ตเมื่อ DayRollover เท่านั้น
- [ ] source=ad เรียก AdService.show() และให้ผลเฉพาะเมื่อ reward callback สำเร็จ
- [ ] ไข่/ปลาทองไม่มีทางได้จาก IAP (test)
- [ ] หน้าโชว์อัตราดึงจาก data เดียวกับที่ใช้สุ่ม

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
