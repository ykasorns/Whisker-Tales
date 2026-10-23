# T-003: data loader + schema validation
Module: core_loop | Priority: P0 | Owner: Sonnet | Depends: T-002

## Goal
โหลด design/data/*.json (relics/talents/monsters/events) ตอน boot + validate ตาม schema §4 ของ contract, fail-fast พร้อม error message ระบุไฟล์/field

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
class ContentRepository { Future<void> loadAll(); List<Relic> relics; ... }

## Acceptance Criteria
- [ ] JSON ผิด schema → throw พร้อมชื่อ field
- [ ] test ครอบ: ไฟล์ดี/ไฟล์พัง/field หาย
- [ ] schema_version ไม่ตรง → error ชัดเจน

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
loader + validator ต้องรองรับไฟล์ v2: `buffs.json` (CONTRACT §4.7), `gear_slots.json` + affix pools, `pets.json`, `research.json`, `pages.json` และ `design/balance/idle_balance_v1.json` (ค่าที่ขึ้นต้น `ASSUMPTION_` ต้องโหลดได้ปกติ) · validate cross-ref: ทุก `effects[]`/skill อ้าง buff id ที่มีจริง · schema ละเอียดของไฟล์ใหม่ Opus กำหนดใน T-043 → T-003 ทำ framework + schema ที่มีแล้วก่อน แล้วเติม schema ตาม T-043

---
## ส่งงาน (2026-10-19)
**ไฟล์**
- `packages/wt_core/lib/src/core/content_repository.dart` — `ContentRepository.loadAll()` → `GameContent` (rules ทุกชุด + `overrides` สำหรับ ProviderScope), `ContentSource`, `ContentError(file, message)`
  - ไฟล์ + schema_version ที่รับ: balance, buffs, skills, gear_slots, wardrobe, road_events (ทั้งหมด v1) · version ไม่ตรง → error ระบุไฟล์
  - error จาก parser ทุกตัว (FormatException/ArgumentError/TypeError) ถูกห่อเป็น `ContentError` พร้อมชื่อไฟล์ — ข้อความเดิมบอก field อยู่แล้ว
  - cross-ref: สกิลอ้างบัฟที่มีจริง · สกิลของคลาสที่มีจริง + ครบช่องต่อคลาส · weapon_art ครบทุกคลาส · ads มี placement ที่โค้ดใช้
- `app/lib/main.dart` — boot: โหลดข้อมูลจาก assets → `Hive.initFlutter` + box → override `saveServiceProvider` → `gameSaverProvider.load()` → แอป · เซฟเองตอน pause · `checkIn` ออฟไลน์ตอน resume · ข้อมูลพัง = หน้า `BootErrorApp` บอกไฟล์/field
- `tools/sync_content.sh` — คัดลอก design/ → `app/assets/content/` (Flutter assets ต้องอยู่ในแพ็กเกจแอป) · `app/pubspec.yaml` + flutter_riverpod, hive_flutter (อยู่ในรายการอนุมัติ) + assets

**Test** (wt_core +6 → 206 · app +3 · analyze 0 ทั้ง 3 package)
- โหลดครบทุกไฟล์แล้วเกมวิ่งได้จริง (idle loop + wallet + offline) · ค่า `ASSUMPTION_` โหลดปกติ
- ไฟล์หาย / schema_version ผิด / field หาย / อ้างบัฟไม่มี / ช่องหาย → `ContentError` ระบุไฟล์ + field
- cross-ref: คลาสไม่มีจริง, weapon_art ขาด, placement ขาด
- app: assets ตรงกับ design/ (ลืม sync = test แดง) · boot โหลดข้อมูล + เซฟ, สร้างแอปได้, pause แล้วเซฟจริง · หน้า error แสดงชื่อไฟล์

**ข้อสังเกต / หนี้**
- relics/talents/monsters/events (โหมดท้าทาย, schema §4.1–4.3) ยังไม่มีไฟล์ → ยังไม่โหลด · pets/research/pages รอ T-043/T-038/T-041
- app ยังไม่มีโฟลเดอร์ android/ios (T-001) → build ลงเครื่องไม่ได้ · ทดสอบ boot ด้วย widget test แทน
- ข้อความ `BootErrorApp` เป็นภาษาอังกฤษตรง ๆ (หน้าสำหรับนักพัฒนา ไม่ใช่ผู้เล่น) — l10n ใน T-004

---
## ตรวจรับ (2026-10-23, Opus) → done
- ✓ JSON ผิด schema / field หาย / schema_version ผิด → error ชื่อไฟล์+field: `content_repository_test.dart` 6 tests · `content_sync_test` กันไฟล์ใน app ไม่ตรง design/
- หนี้เดิม: relics/talents/monsters/events ของโหมดท้าทาย = T-026 (กลุ่ม B) · pets/research ทำแล้ว (T-038/T-041) · หน้า/มอนต่อบท → T-043 (`design/data/chapters.json`, D-032)
