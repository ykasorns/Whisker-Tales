# T-023: cloud sync
Module: save_cloud | Priority: P1 | Owner: Sonnet | Depends: T-022

## Goal
Game Center (iOS) / Play Games Services (Android) ผ่าน games_services, conflict rule: total_runs → goldfish → updated_at

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
CloudSync.sync() -> SyncResult

## Acceptance Criteria
- [ ] conflict ทุก case มี test
- [ ] ไม่มี network = เล่น offline ได้ปกติ ไม่ block
- [ ] ไม่แตะ personal data ใดๆ นอก platform service

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
