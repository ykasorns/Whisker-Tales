# T-002: core contracts + GameState skeleton
Module: core_loop | Priority: P0 | Owner: Sonnet | Depends: T-001

## Goal
สร้าง `packages/wt_core/lib/src/core/contracts/` (abstract interfaces ทุก module) + `packages/wt_core/lib/src/core/providers.dart` + GameState/RunState enum + state machine โครง walk→encounter→resolve→walk ตาม GDD §3.2 — export ที่จำเป็นทั้งหมดผ่าน barrel `packages/wt_core/lib/wt_core.dart` (path ตาม GAME_CONTRACT §2/§3 v1.2, D-001)

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

---
## Worker summary (2026-10-13)

**หมายเหตุลำดับ:** T-001 ยังอยู่ doing (native project ยังไม่ได้ `flutter create`) แต่ Flutter SDK มีในเครื่องแล้ว → `flutter pub get/analyze/test` ของ wt_core, wt_mode_story, app รันได้จริง · ต่อยอดไฟล์ที่ T-033 สร้างไว้ก่อน (ไม่สร้างทับ)

**ไฟล์ที่แตะ**
- `packages/wt_core/lib/src/core/contracts/`
  - `combat.dart` — `ICombatEngine` (start/tick(dtMs)/events/useSkill ตาม card T-007/T-008 v2), `IBuffEngine`, `CombatSetup`, `CombatEvent` (+`UnitDefeated`, `CombatEnded`)
  - `game_mode.dart` — MODE_PLUGIN_SPEC §3–§4: `GameMode`, `EncounterSource`, `Encounter`, `EncounterPreview`, `EncounterType`, `RunConfig`, `RunResult`, `RunOutcome`, `WinCondition`, `RewardResult`, `ModeSaveState`, `ModeManifest.fromJson`, `UnlockRule`, `IModeRegistry`
  - `run_systems.dart` — `IRunManager`, `IEncounterGenerator`, `IItemSystem`, `ISynergyResolver`, `ITalentSystem`, `EffectTrigger` (vocabulary §4.5), `EffectContext`
  - `services.dart` — `IMetaProgression`, `ISaveService`, `IAudioService`, `IIapService`, `IParentalGate`
  - doc comment ทุก interface อ้าง GDD/spec § (ตรวจด้วยสคริปต์ — ไม่เหลือตัวไหนขาด)
- `packages/wt_core/lib/src/core/state/game_state.dart` — `GameState` {boot, ageGate, hub, run} + `GameStateMachine` · `RunPhase`/`RunState` + `RunStateMachine` (walk → encounter → resolve → walk, end ได้จากทุก phase ที่ active, transition ผิด = `StateError`)
- `packages/wt_core/lib/src/core/providers.dart` — เพิ่ม `gameStateProvider`, `runStateProvider`
- `packages/wt_core/lib/wt_core.dart` — export ครบ
- **lint barrel-only:** `app/analysis_options.yaml` + `packages/wt_mode_story/analysis_options.yaml` (ใหม่) ตั้ง `implementation_imports: error` · ทดสอบด้วยไฟล์ probe ที่ import `package:wt_core/src/...` → analyzer ขึ้น error จริง แล้วลบ probe ออก
- test: `test/core/state/game_state_test.dart` (8), `test/core/contracts/game_mode_test.dart` (5)

**Acceptance**
- [x] state machine เปลี่ยน state ครบวงจรใน unit test (3 รอบ walk→encounter→resolve→walk แล้วจบ + transition ผิดถูกปฏิเสธ)
- [x] ทุก interface มี doc comment ระบุ GDD section
- [x] (Amendment v1.1) contracts GameMode / EncounterSource / WinCondition / ModeRegistry / ModeManifest · lint barrel-only
- `flutter analyze` 0 issue ทั้ง wt_core / wt_mode_story / app · `flutter test` wt_core 34/34

**ข้อสังเกต**
1. `IModeRegistry` เป็น interface เท่านั้น — implementation อยู่ T-031 ตาม card นั้น จึงยังไม่แก้ `app/lib/modes.dart`
2. spec §4 ยกตัวอย่างแค่ `unlock.flag` → ผมกำหนด key ของอีกสองแบบเป็น `fish_total` → `amount`, `boss_cleared` → `boss` — Opus ช่วยยืนยันหรือแก้ใน spec
3. `GameState` เพิ่ม `ageGate` ตาม v0.4 (T-040) · `hub` = หน้าฟาร์ม idle (D-002)
4. `IEncounterGenerator.generate` คืน `List<Encounter>` แทน `NodeMap` ใน card T-006 — ยังไม่มี Fork ใน type; T-006 ขยายได้ (Opus ตัดสินว่าจะเพิ่ม `NodeMap` ไหม)

---
## ตรวจรับ (2026-10-23, Opus) → done
- ✓ state machine ครบวงจร: `test/core/state/game_state_test.dart` (walk → encounter → resolve, boot → age gate → hub)
- ✓ interface มี doc comment อ้าง GDD/CONTRACT
- ค้างโดยตั้งใจ: ModeRegistry implementation = T-031 (กลุ่ม B โหมดท้าทายนิทาน)
