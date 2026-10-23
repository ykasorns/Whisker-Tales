# T-024: audio service
Module: audio | Priority: P2 | Owner: Sonnet | Depends: T-002

## Goal
BGM/SFX service, ducking, ปิด/เปิดแยกใน settings — asset จาก assets/game/audio

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
AudioService.playBgm(id)/sfx(id)

## Acceptance Criteria
- [ ] สลับ scene แล้ว BGM crossfade ไม่กระตุก
- [ ] mute ทำงานทันทีทุกที่

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## ส่งงาน + ตรวจรับ (2026-10-23, Opus) — D-034 → done
- wt_core `src/audio/audio.dart`: `AudioRules` (audio.json) · `AudioOutput` (seam) · `AudioService` implements `IAudioService` (`playBgm`/`playSfx`, crossfade ด้วย `tick`, mute, pause/resume) · providers + content + save `settings.bgm/sfx`
- app: `audio/player_output.dart` (audioplayers) · driver เลือกเพลงตามฉาก (บอส/ฟาร์ม) · เสียงจาก combat/idle/level-up/ถัก/ฟัก · สวิตช์ในหน้าร้าน · lifecycle
- ✓ AC สลับฉากแล้ว crossfade ไม่กระตุก: `audio_test` (ระดับเสียงขยับทีละเฟรมไม่เกินสัดส่วน, เพลงเก่าหยุดเมื่อจบ fade, สลับกลางทางไม่ค้าง 2 เพลง)
- ✓ AC mute ทันทีทุกที่: `audio_test` + `app/test/sound_switches_test` (กดสวิตช์ → หยุดทันที + เซฟ)
- Test: wt_core 290 · app 21 · analyze 0 · golden หน้าร้านอัปเดต · APK arm64 26.9 MB
- ข้อสังเกต: ยังไม่ได้ฟังบนเครื่องจริง (ไม่มี emulator) → RELEASE_CHECKLIST
