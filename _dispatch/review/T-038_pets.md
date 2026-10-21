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

---
## ส่งงาน (2026-10-20)
**ไฟล์**
- `core/contracts/pets.dart` — `HatchResult` (+cookies, wasPity), `PetsState` (Save v3 `pets`)
- `src/pets/pets.dart` — `PetsRules.fromJson`, `Pets` (hatch egg/ad/fish, rates, pity, nextFishCost, quota, deploySlots, deploy/undeploy, passiveBp, withPassive, partners, snapshot/restore)
- `design/data/pets.json` (ใหม่) · `design/art/pet_prompts.md` (prompt ภาพ 6 ตัว × 2 ท่า)
- idle loop: `partners` → เพื่อนที่ออกรบอยู่ในทุกการสู้ (ช่อง partner) · แมวได้ passive
- providers: `petsRulesProvider` (null = ไม่มีเพื่อน), `petsProvider` · ContentRepository + GameSaver (pets + daily.fish_pulls)
- app: แท็บเพื่อนสัตว์ (ฟักไข่ 3 ทาง + อัตรา + การันตีโชว์ทุกครั้ง, ผลฟักเด้ง, รายชื่อ 6 ตัว + ดาว + เงา, แตะเพื่อออกรบ/พัก), เพื่อนเดินตามโมจิในฉาก

**Test** (wt_core +11 → 225 · app 7 + golden หน้าเพื่อนสัตว์ TH/EN · analyze 0)
- อัตราตรงตาราง (chi-square 100k) · การันตีตำนาน ≤ 40 และไม่รีเซ็ตข้ามวัน
- ปลาทอง 5 ครั้ง/วัน 300/450/675/1013/1519 · ย้อนนาฬิกาไม่รีเซ็ต · วันใหม่รีเซ็ต · ตามบท +8%
- ไม่มีไข่/ปลาทอง = ไม่เกิดอะไร · โฆษณาต้องดูจบเท่านั้น · ซ้ำ → ดาว → ขนม
- ช่องออกรบตามบท · passive + partner ATK · partner ตีจริงใน idle loop · ฟักไม่มีทางได้ไข่/ปลาทองคืน · save round-trip (+ ใน GameSaver)

**ข้อสังเกต**
- AC "ไข่/ปลาทองไม่มีทางได้จาก IAP" — ยังไม่มีโค้ด IAP (T-025) · test ยืนยันฝั่งฟัก + ตู้เสื้อผ้า IAP ปลดได้แค่หน้าตา
- ระบบเลเวลเพื่อนสัตว์ด้วยขนมยังไม่ทำ · ภาพเพื่อนสัตว์ยังไม่มี (emoji)
