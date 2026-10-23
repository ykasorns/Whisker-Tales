# T-027: avatar — frame animation + gear on anchors (P0)
Module: avatar | Priority: P0 | Owner: Sonnet | Depends: T-001, T-045
> D-005 · spec: GDD v0.5.1 §2, §4 · contract v2.2

## Goal
ตัวละครแมวใน Flame ตามแบบ A + B ที่ทดสอบในเว็บต้นแบบแล้ว: เล่นท่าเต็มตัวตาม skin (ยืน, เดิน 3 วน 1-2-3-2, โจมตีมือเปล่า 5 ตามคลาส, หลบ, เจ็บ, ชนะ, นอน) และวางอุปกรณ์ที่เห็นบนตัว (อาวุธ + โล่/มีดเล่ม 2, หมวก, ผ้าพันคอ, กระเป๋า) ตามจุดยึดต่อเฟรมจาก `design/art/anchors_mochi.json` — ลำดับวาด: กระเป๋า → มีดเล่ม 2 → ตัว → ผ้าพันคอ → หมวก → โล่ → อาวุธหลัก · มอน/บอสใช้ frame animation เดียวกัน (ไม่มีจุดยึด)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
AvatarComponent(skinId, anchors) / play(animId) / setGear(slotId, styleId|null) / setClass(classId) · Flame component ไม่มี game logic

## Acceptance Criteria
- [ ] ตำแหน่ง/มุมอุปกรณ์ตรงกับเว็บต้นแบบทุกเฟรม (golden test 13 เฟรม × 4 คลาส)
- [ ] เปลี่ยน skin / อุปกรณ์ / คลาส ได้ระหว่างเล่นโดยไม่สร้าง component ใหม่
- [ ] อุปกรณ์ 1 ภาพใช้ได้ทุกท่า (grip + size จาก JSON) — เพิ่มแบบใหม่ไม่ต้องแก้โค้ด
- [ ] เท้าอยู่บนเส้นพื้นทุกเฟรม (ใช้ padding ของ slicer ต่อ sheet)
- [ ] 60 fps บนเครื่อง Android ระดับกลาง ขณะมีแมว + มอน 3 + เพื่อนสัตว์ 3

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment D-012 (2026-10-19)
วาดอุปกรณ์ตาม `anchors_mochi.json → render_order` (ไม่ใช่แปะทับ): ของหลังตัว → แมว → ผ้าพันคอ + วาดแมวซ้ำเหนือเส้น `chin` และใน `occluders` → หมวกที่ `head + hat` หมุน `hatDeg` → อาวุธ + วาดแมวซ้ำในวงกลม `paw_radius` รอบ `fp` · `fpBehind` = อาวุธหลังตัว · ภาพที่จะวาดต่อช่องมาจาก `Wardrobe.lookFor(slot, classId)` / `offHandFor(classId)` (T-045) · อ้างอิงการทำงาน: เว็บต้นแบบ v13 `drawMochiA` + `tools/gear_fit/render.py`

---
## ส่งงาน (2026-10-19)
**ไฟล์**
- `packages/wt_core/lib/src/avatar/` — `avatar_rules.dart` (`AvatarRules.fromJson` ← anchors_mochi.json), `avatar_layout.dart` (`layoutAvatar` = ลำดับวาด D-012 แบบ pure: `DrawCat` / `DrawGear` / `RestampCat`), `avatar_renderer.dart` (`paintAvatar` บน dart:ui Canvas: clip แล้ววาดแมวซ้ำ), `avatar_component.dart` (`AvatarComponent` ของ Flame: play / setGear / setClass / setSkin — ไม่มี game logic, cache ops ต่อเฟรม)
- `design/art/anchors_mochi.json` + `schema_version` + `ground_pad_px` (= PAD ของ slicer) · `ContentRepository` โหลด + เช็กว่าทุกภาพอาวุธ/มือหลังของ wardrobe มี grip
- `tools/gear_fit/export_layout.py` → `test/avatar/layout_expected.json` (ค่าจากเครื่องมือที่ใช้จูนต้นแบบ) · `tools/sync_sprites.py` → `app/assets/game/{cat,gear}` (อุปกรณ์ตัดขอบให้ grip ตรง)
- `app/lib/game_view.dart` — `GameView` (Flame) โมจิเดิน + อุปกรณ์จาก `Wardrobe.lookFor/offHandFor` + คลาสปัจจุบัน (อัปเดตทุก 1 วิ)

**Test** (wt_core +8 → 214 · app +1 → 4 · analyze 0 ทั้ง 3 package · APK build ผ่าน)
- **layout ตรงกับเครื่องมือจูนต้นแบบทุกเฟรม × ทุกคลาส (48 ชุด ทุกค่า ±0.01)**
- golden ภาพจริง 13 เฟรม × 4 คลาส (`test/avatar/goldens/`) — วาดผ่าน Flutter canvas ตรวจด้วยตาแล้ว
- ใส่เฉพาะของที่แสดง · ท่านอนไม่มีจุดยึด = แมวอย่างเดียว · ท่าหลบอาวุธอยู่หลังตัว · ground pad = PAD ของ slicer
- component: วนเดิน 1-2-3-2, ท่าโจมตีตามคลาส, เปลี่ยนอุปกรณ์/คลาสโดยไม่สร้าง component ใหม่, id ผิด throw
- app: เปิดแล้ว GameView โหลดโมจิได้และเดินอยู่

**ข้อสังเกต / หนี้**
- AC 60 fps บนเครื่องกลาง **ยังไม่ได้วัด** (ไม่มีเครื่อง Android/emulator) — วาด 1 แมว = ~5–9 drawImage + clip 2–3 ครั้ง/เฟรม น่าจะสบาย
- มอน/บอสใน Flame + ฉาก parallax + HUD = T-042 · skin อื่นยังไม่มีภาพ (component รองรับ `setSkin` แล้ว — key `<skin>/<frame>`)
- golden สร้างจากโค้ดเอง (`--update-goldens`) ใช้กันถอยหลัง; ความถูกต้องเชิงตำแหน่งยืนยันด้วย test เทียบค่ากับเครื่องมือต้นแบบ

---
## ตรวจรับ (2026-10-23, Opus) → done
- ⏭ AC "golden 13 เฟรม × 4 คลาส ตรงเว็บต้นแบบ" ถูกแทนด้วย **D-024/D-029** (ชุดคลาสวาดทั้งตัว ไม่ใช้จุดยึดอุปกรณ์บนตัวแล้ว) → n/a
- ✓ เปลี่ยนคลาส/ชุดระหว่างเล่นไม่สร้าง component ใหม่ (`_applyLook`) · ✓ เท้าบนพื้น (slicer `--align feet/ground`)
- ⚠ 60 fps บนเครื่องกลาง ยังไม่ได้วัด (ไม่มีเครื่อง) → ใส่ใน RELEASE_CHECKLIST ให้ลองบนเครื่องจริงตอน Internal testing
