# T-042: idle UI panels — farm, craft/compare, hatch, research, offline popup
Module: ui_panel | Priority: P1 | Owner: Sonnet | Depends: T-014,T-034,T-035,T-036,T-038,T-041
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
แผงโซนล่าง 40% ตาม GDD v0.4 §11: ฟาร์ม (ตะกร้ากลาง + ท้าบอส + เมนู), ถักของ (เลือกช่อง 8 + การ์ดเทียบ 2 ใบ + ดาว ✨), ฟักไข่ (3 ปุ่ม + ดูอัตรา), ห้องสมุด, popup รางวัลออฟไลน์ (ไม่มีปุ่ม ×2) · HUD พลังแมว แบบย่อ K/M · PM แตกเป็น .a/.b ได้ถ้าใหญ่เกิน 1 วัน

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
FarmPanel / CraftPanel / HatchPanel / ResearchPanel / OfflineRewardSheet

## Acceptance Criteria
- [ ] ปุ่มโฆษณามีป้าย 📺 ชัดเจน + จำนวนเหลือวันนี้
- [ ] อัตราเกรด/อัตราฟักแสดงก่อนกดได้ทุกครั้ง
- [ ] ปุ่มหลัก Ø ≥ 72pt ในโซนนิ้วโป้ง · ไม่มีตัวหนังสือเป็นเงื่อนไขการเล่น
- [ ] golden test ทุก panel TH/EN

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
