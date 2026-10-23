# T-045: wardrobe (styles, chosen look, collection)
Module: wardrobe | Priority: P1 | Owner: Sonnet | Depends: T-036,T-022
> D-004 · spec: GDD v0.5 · contract v2.1

## Goal
ตู้เสื้อผ้าตาม GDD v0.5 §4.2: ถักได้แบบใหม่ครั้งแรก → ปลดถาวร · เลือกหน้าตาต่อช่องแยกจากของที่ให้พลัง · สมุดสะสม (ยังไม่ได้ = เงาดำ) · แบบจาก IAP ใช้ระบบเดียวกัน · อาวุธแสดงแบบของคลาสปัจจุบัน

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
Wardrobe.unlocked / unlock(styleId) / choose(slotId, styleId|null) / lookFor(slotId, classId) -> styleId

## Acceptance Criteria
- [ ] รีไซเคิลของแล้วหน้าตายังปลดอยู่
- [ ] หน้าตาไม่มีผลต่อ stat (test)
- [ ] เปลี่ยนคลาสแล้วอาวุธเปลี่ยนเป็นแบบของคลาสนั้นอัตโนมัติ
- [ ] save/restore (Save v3 `wardrobe`)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment D-005 (2026-10-18)
- ช่องที่เห็นบนตัว: อาวุธ หมวก ผ้าพันคอ กระเป๋า · ช่องอื่นสะสมแบบเป็นไอคอนในสมุด
- เพิ่ม **skin** (`wardrobe.skin`, `skins_unlocked`): เปลี่ยนชุดท่าเต็มตัวทั้งชุด · อุปกรณ์ที่เห็นบนตัวยังติดทับ skin ได้
- Interface เพิ่ม: `Wardrobe.skin` / `chooseSkin(skinId)`

---
## ส่งงาน (2026-10-19)
**ไฟล์**
- `core/contracts/wardrobe.dart` — `IWardrobe`, `WardrobeState` (Save v3 `wardrobe`: unlocked/chosen/skin/skins_unlocked · chosen `none` = ซ่อน), `CollectionEntry`
- `src/wardrobe/wardrobe.dart` — `WardrobeRules` + `Wardrobe` (unlock / choose / lookFor / offHandFor / collection / skins / grantPurchase / snapshot / restore)
- `design/data/wardrobe.json` (ใหม่) — tier 3 ระดับ, ช่องที่เห็นบนตัว, ภาพอาวุธ/มือหลังต่อคลาส, skin base + adventurer (ผ่านหน้า 10), iap ว่าง
- providers: `wardrobeRulesProvider`, `wardrobeProvider` · ตะกร้าเรียก `wardrobe.unlock` ตอนถัก (isNewStyle มาจากตู้จริงแล้ว)
- **D-012 ให้ของดูใส่จริง:** `design/art/anchors_mochi.json` เพิ่ม neck/chin/hat/hatDeg/back/fpBehind/occluders ต่อเฟรม + `render_order` · GDD v0.5 §2 · T-027 amend · เว็บต้นแบบ v13

**Test** (`test/wardrobe/` +7 → รวม 136 · analyze 0 ทั้ง 3 package)
- สมุด 24 แบบ + เงา · หน้าตาตามของที่ใส่ · อาวุธเปลี่ยนตามคลาส (dagger_2 → staff_2) · ไอคอนช่องไม่เห็นบนตัว · ของมือหลังตามคลาส
- เลือกแบบที่ปลด/ซ่อน/กลับไปตามของ · แบบที่ยังไม่ปลด/ผิดช่อง throw · skin ปลดตามความคืบหน้า · ซื้อของตกแต่งปลดแค่หน้าตา
- save round-trip + validate · ถักแล้วปลด, รีไซเคิลแล้วยังปลดอยู่, เปลี่ยนหน้าตาไม่เปลี่ยน stat

**ข้อสังเกต**
- skin `adventurer` ยังไม่มีภาพ (ต้อง gen 13 เฟรม + วัดจุดยึดใหม่) · `iap` ว่างจนกว่าจะมีของตกแต่งขาย (T-025 parental gate)
- หน้าจอตู้เสื้อผ้า/สมุดสะสม = T-042 UI

---
## ตรวจรับ (2026-10-23, Opus) → done
- ✓ รีไซเคิลแล้วยังปลด · ไม่มีผลต่อ stat · save/restore: `wardrobe_test.dart`
- เปลี่ยนเป็นสมุดสะสม + ชุดตามคลาส (D-024/D-029) → AC "อาวุธเปลี่ยนตามคลาส" ถูกแทนด้วยชุดคลาสวาดทั้งตัว ✓
