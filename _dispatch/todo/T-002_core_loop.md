# T-002: core contracts + GameState skeleton
Module: core_loop | Priority: P0 | Owner: Sonnet | Depends: T-001

## Goal
สร้าง lib/core/contracts/ (abstract interfaces ทุก module) + lib/core/providers.dart + GameState/RunState enum + state machine โครง walk→encounter→resolve→walk ตาม GDD §3.2

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
abstract class ICombatEngine / ITalentSystem / ISaveService ฯลฯ + StateNotifier<RunState>

## Acceptance Criteria
- [ ] state machine เปลี่ยน state ครบวงจรใน unit test
- [ ] ทุก interface มี doc comment ระบุ GDD section

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## Amendment v1.1 (MODE_PLUGIN_SPEC)
- contracts เพิ่ม: `GameMode`, `EncounterSource`, `WinCondition`, `ModeRegistry`, `ModeManifest` ตาม spec §3–§4
- lint rule: package ภายนอก import ได้เฉพาะ `package:wt_core/wt_core.dart`
