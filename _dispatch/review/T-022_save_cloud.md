# T-022: save local + versioned schema
Module: save_cloud | Priority: P0 | Owner: Sonnet | Depends: T-002

## Goal
Hive local save ตาม schema contract §4.4 + migration framework (bump save_version ต้องมี migration+test)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
SaveService.load()/save()/migrate(from,to)

## Acceptance Criteria
- [ ] kill app กลางทาง = ไม่ corrupt (atomic write)
- [ ] migration v1→v2 ตัวอย่างมี test

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## Amendment v1.1 (MODE_PLUGIN_SPEC)
- save schema เริ่มที่ v2: namespace `modes.<id>` (spec §5) — core เก็บ/คืน blob ต่อโหมดโดยไม่ตีความ
- conformance: roundtrip encode/decode ของ ModeSaveState

---
## Amendment v2.0 (D-002, 2026-10-12)
ใช้ **Save v3** (CONTRACT §4.6) (conflict rule ใหม่ implement ใน T-023) · ยังไม่ต้อง migrate (ไม่มี user) แต่ต้องมี test decode v3 · T-022 แค่เก็บ field (`clock`, `daily`, `age`, `entitlements`) — logic merge อยู่ T-023, logic นาฬิกาอยู่ T-033 (ไม่ต้อง depend)

---
## ส่งงาน (2026-10-19)
**ไฟล์**
- `src/save/save_service.dart` — `SaveService` (load / save / migrate), `SaveStore` + `HiveSaveStore` + `MemorySaveStore`, `SaveLoadResult` · **2 ช่องสลับกัน + generation + checksum (FNV-1a)** → แอปถูกปิดกลางการเขียน = ช่องเดิมยังดี · ช่องใหม่สุดเสีย → ใช้อีกช่อง (`recovered`)
- `core/game_save.dart` — `GameSaver` (capture / restore / load / save): รวมทุกโมดูลเป็น Save v3 (profile/wallet, idle, gear + auto_craft, cat, wardrobe, daily/ads, clock, entitlements) · ส่วนที่ยังไม่มีเจ้าของ (pets, research, age, modes, settings) ถือผ่านไม่แตะ · โหลด = เปิดแอป → `clock.tick()` (วันใหม่รีเซ็ตทันที)
- `core/clock/game_clock.dart` — `restore(ClockState)` + `ClockState.toJson/fromJson` · `MemoryWallet.setBalances`
- providers: `saveServiceProvider` (boot override เป็น Hive), `gameSaverProvider`

**Test** (`test/save/` +13 → รวม 200 · analyze 0 ทั้ง 3 package)
- เกมใหม่ = ไม่มีเซฟ · สลับช่อง + โหลดอันใหม่สุด · **ตัดการเขียนกลางทาง 4 จุด → ได้เซฟก่อนหน้าครบ** · checksum ไม่ตรง → ใช้ช่องเก่า
- migration v1→v2→v3 (ตัวอย่างใน test) · ขาดขั้น / เซฟใหม่กว่าแอป → error · เขียนผิด version → ปฏิเสธ
- Hive จริงใน temp dir · ตัวอย่าง Save v3 ใน contract parse ได้และมีครบทุก section
- **เล่น → เซฟ → เปิดใหม่ = ทุกอย่างกลับมา** (เงิน, หน้า, อุปกรณ์ + เลเวลช่อง + ตะกร้า, คลาส/เลเวล, ตู้เสื้อผ้า, โควต้าโฆษณา, ถักอัตโนมัติ) · ช่วงออฟไลน์ยังอยู่หลังโหลด · ข้ามวันแล้วโควต้ารีเซ็ต · section ที่ไม่มีเจ้าของคงเดิม · section พังบอกชื่อ

**ข้อสังเกต / หนี้**
- ยังไม่มี migration จริง (Save v3 เป็นรุ่นแรกที่ใช้ — D-001/D-002)
- แอปยังไม่ได้ต่อ: boot ต้อง `Hive.initFlutter()` → เปิด box → override `saveServiceProvider` + โหลดข้อมูล JSON (T-003) → `gameSaverProvider.load()` · autosave ตอน pause/ทุก N วินาที = งานแอป/T-042
- ของที่ถักแล้วรอเลือก (pending) ไม่เซฟ · เหตุการณ์ระหว่างทางไม่เซฟ (ตั้งใจ, D-013)
- cloud sync + conflict rule = T-023
