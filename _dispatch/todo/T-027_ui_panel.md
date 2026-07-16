# T-027: art integration + layered sprite rig loader
Module: ui_panel | Priority: P1 | Owner: Sonnet | Depends: T-014,T-026

## Goal
โหลด sprite rig แบบ layered body-part (contract §5 — ห้าม flatten), boiling line 3-frame player, นำเข้า Anchor assets ชุดแรก

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
CatRig.load(catId) / RigRenderer

## Acceptance Criteria
- [ ] สลับ cosmetic layer runtime ได้ (พิสูจน์ pathway สู่ Mochi Studio)
- [ ] boiling line 8fps ไม่กิน perf (60fps คงที่บนเครื่อง mid-range)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
