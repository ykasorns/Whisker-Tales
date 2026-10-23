# T-004: l10n TH/EN setup
Module: ui_panel | Priority: P0 | Owner: Sonnet | Depends: T-001

## Goal
ตั้งระบบ localization TH/EN (flutter gen-l10n) ที่ `app/lib/l10n/` (path ตาม GAME_CONTRACT §2 v1.2, D-001), โครง arb files, กฎ: ห้าม hardcode UI string — content string (relic/talent/monster ชื่อ ฯลฯ) มาจาก `design/data/*.json` ผ่าน `name_th`/`name_en` อยู่แล้ว ไม่ต้องผ่าน arb

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
AppLocalizations.of(context).xxx

## Acceptance Criteria
- [x] สลับภาษา runtime ได้
- [x] มี lint/test กันการ hardcode UI string ใน `packages/wt_core/lib/src/ui/` และ `app/lib/`

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## ผล (2026-10-22, Opus) — D-028
- `l10n.yaml` + `lib/l10n/app_{th,en}.arb` (~95 ข้อความ) → `lib/l10n/gen/` (AppLocalizations) · แปลงจาก `strings.dart` เดิมด้วยสคริปต์ ชื่อเรียกเหมือนเดิม · `className` (ICU select), `level`, `catTitle`, `cooldownSeconds`, `switchLanguage`
- ภาษาใน `langProvider` → MaterialApp locale · ปุ่มสลับในร้านค้า · เซฟใน `settings.lang`
- `test/no_hardcoded_text_test.dart` สแกนข้อความตรง ๆ ใน UI · `test/_l10n.dart` helper

**Test** app 18 (+2: สแกนข้อความ, สลับภาษาระหว่างเล่นแล้วเซฟ) · wt_core 278 · analyze 0 · golden อัปเดต (ชื่อคลาส/ป้าย Lv/ปุ่มภาษา)

---
## ตรวจรับ (2026-10-23, Opus) → done
- ✓ สลับภาษา runtime + เซฟ: `panels_golden_test` "the language switches while playing and is saved"
- ✓ กัน hard-code: `no_hardcoded_text_test.dart`
