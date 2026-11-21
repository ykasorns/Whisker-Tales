# T-021: meta progression
Module: meta_progression | Priority: P1 | Owner: Sonnet | Depends: T-003,T-005

## Goal
ปลาทองถาวร, ตารางปลดล็อก GDD §7, starting relic slot, village level

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
MetaProgression.unlock(id) / canAfford(id)

## Acceptance Criteria
- [ ] ปลดล็อกทั้งหมด data-driven จาก JSON
- [ ] ตายใน run ก็ได้ปลาทอง (Fail Forward test)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
currency ถาวร 4 สกุล (ปลาทอง/ไหมพรม/ไข่/ขนม) + ร้านนกฮูก + ปลดล็อกสกิล/ช่องตามบท · ตัด starting relic slot/village level ออกจากโหมดหลัก (ย้ายไปเป็น meta ของโหมดผจญภัย v1.1) · **D-053 supersedes ข้อห้ามเดิม: IAP เพิ่มได้เฉพาะไหมพรม/ปลาทองผ่าน `IapService`; ไข่/ขนมยังห้ามขาย**

---
## ตรวจรับ (2026-11-21, Claude, D-071): ถูกระบบที่มีอยู่แทนที่

| ข้อในการ์ด | ที่ทำอยู่แล้ว | เทสต์ |
|---|---|---|
| currency ถาวร 4 สกุล | `Currency` ใน `wt_core/lib/src/core/contracts/rewards.dart:4` · เซฟ/โหลดที่ `core/game_save.dart:74` และ `:151` | `test/save/game_save_test.dart` |
| ใช้ปลาทอง (ห้องสมุด, อัพช่อง, ฟักไข่) | `research/research.dart:309`, `gear/gear_basket.dart:229`, `pets/pets.dart:457` | research, gear, pets tests |
| ร้านนกฮูก + IAP เฉพาะไหมพรม/ปลาทอง (D-053) | `app/lib/ui/shop.dart` ผ่าน `openShop` + parental gate · `iap/iap.dart` | `app/test/shop_test.dart`, `test/iap/iap_test.dart` |
| ปลดช่องตามบท | `gear/gear_basket.dart:67` อ่าน `slot_unlocks` จาก JSON | `test/gear/gear_test.dart:36` |
| ปลดสกิลตามบท | เปลี่ยนเป็นตามเลเวลแมวตาม D-004: `cat/cat_class.dart:62` อ่าน `skill_slot_levels` | `test/cat/cat_test.dart:168` |
| ปลดโหมดเสริม | `wt_mode_story/assets/manifest.json:9` (`boss_cleared` eraserking) อ่านผ่าน `UnlockRule` | `test/core/contracts/game_mode_test.dart:33`, `app/test/story_adventure_test.dart` |
| ตายใน run ก็ได้ปลาทอง (Fail Forward) | `RunManager.endRun` + `wt_mode_story/lib/src/story_mode.dart:94` | `test/core/run_manager_test.dart` และใหม่ `app/test/story_boss_test.dart` (ตายจริง → กระเป๋า → เซฟ/โหลด) |
| ตัด starting relic slot / village level | ตาม Amendment v2.0 (ย้ายไป meta ของโหมดผจญภัย v1.1) | ไม่มี |

เหลือให้ YK เลือก: `IMetaProgression` ไม่มีตัว implement (ลบหรือเก็บเป็นเอกสาร) · ข้อมูลค้าง `skills.unlocked_by_chapter` เสนอให้ T-029 ลบ

---
## ตรวจรับ YK (2026-11-21)
YK ยืนยัน D-071: ลบ `IMetaProgression` แล้ว · `skills.unlocked_by_chapter` เก็บไว้เพราะ balance sim ยังใช้
