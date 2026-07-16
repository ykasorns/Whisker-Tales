# T-004: l10n TH/EN setup
Module: ui_panel | Priority: P0 | Owner: Sonnet | Depends: T-001

## Goal
ตั้งระบบ localization TH/EN (flutter gen-l10n), โครง arb files, กฎ: ห้าม hardcode string

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
AppLocalizations.of(context).xxx

## Acceptance Criteria
- [ ] สลับภาษา runtime ได้
- [ ] มี lint/test กันการ hardcode string ใน lib/ui

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
