# T-004: l10n TH/EN setup
Module: ui_panel | Priority: P0 | Owner: Sonnet | Depends: T-001

## Goal
ตั้งระบบ localization TH/EN (flutter gen-l10n) ที่ `app/lib/l10n/` (path ตาม GAME_CONTRACT §2 v1.2, D-001), โครง arb files, กฎ: ห้าม hardcode UI string — content string (relic/talent/monster ชื่อ ฯลฯ) มาจาก `design/data/*.json` ผ่าน `name_th`/`name_en` อยู่แล้ว ไม่ต้องผ่าน arb

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
AppLocalizations.of(context).xxx

## Acceptance Criteria
- [ ] สลับภาษา runtime ได้
- [ ] มี lint/test กันการ hardcode UI string ใน `packages/wt_core/lib/src/ui/` และ `app/lib/`

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
