# T-041: research — owl library tree, timers, queue, ad speed-up
Module: research | Priority: P0 | Owner: Sonnet | Depends: T-033,T-039,T-003
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
ห้องสมุดนกฮูก GDD v0.4 §7: tree + prerequisite, ราคา/เวลาโตตามเลเวล (JSON), คิว 1 (ปลดคิว 2 ใน tree), node `offline_cap` (+10 นาที/เลเวล), node ปลดฟีเจอร์ · ad ลดเวลา −max(30 นาที, 25% ที่เหลือ) ≤5/วัน ผ่าน AdService

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
Research.start(nodeId) / speedUpWithAd() / Stream<ResearchCompleted> / levels

## Acceptance Criteria
- [x] ends_at เทียบกับ GameClock.effectiveNow (ย้อนนาฬิกาไม่ทำให้งานถอย)
- [x] ไม่มี path เร่งด้วยเงินจริง/IAP
- [~] แจ้งเตือนเฉพาะ 'วิจัยเสร็จ' และปิดได้ใน settings
- [x] เวลา/ราคาตรงสูตร JSON

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## ผล (2026-10-21, Opus) — D-020
- `src/research/research.dart` — `ResearchRules.fromJson`, `Research` (start, tick, remaining, adCut, speedUpWithAd, blockOf/missing, queueSlots, statBp/withBonus, offlineCapLevel, snapshot/restore) · contract เพิ่ม `ResearchTask`, `ResearchState` (IResearch ไม่เปลี่ยน)
- `design/data/research.json` (ใหม่, 5 node) · ContentRepository + `researchRulesProvider`/`researchProvider` · idle loop ใส่โบนัส stat · OfflineReward อ่านเลเวลหมอนนุ่มเอง (เดิม checkIn() ไม่ส่งเลเวล = node ไม่มีผล) · GameSaver (research + settings.notify_research)
- app: แท็บห้องสมุด (โต๊ะ + นับถอยหลัง + แถบความคืบหน้า, ปุ่ม 📺 x/5, สวิตช์แจ้งเตือน, รายการ node พร้อมราคา/เวลา/เหตุผลที่ล็อก) · driver tick ทุก 0.25 วิ · แถบ "วิจัยเสร็จแล้ว"

**Test** (wt_core +13 → 238 · app 7 + golden ห้องสมุด TH/EN · analyze 0 · balance sim PASS 14.6 วัน / 5.5%)
- สูตรเวลา 60/96/154 วิ, cap 4 ชม. ที่ Lv13 · ราคา 100/145/210 · โต๊ะ 2 = 500 / 10 นาที
- ย้อนนาฬิกาไม่ถอย · เลื่อนไปข้างหน้า = เสร็จ · งานที่ครบตอนออฟไลน์เสร็จใน tick แรกหลังโหลด
- คิว 1 → 2 · prerequisite · ปลาทองไม่พอ = ไม่หัก · โฆษณา: ตัดงานที่เสร็จก่อน, max(30 นาที, 25%), ข้าม/หมดโควต้า = ไม่ตัด
- หมอนนุ่ม Lv3 = cap 8 ชม. 30 นาที · stat node % · save round-trip + ทิ้งงานเสีย · สแกน: research ใช้แค่ goldfish ไม่มีคำ iap/purchase/billing

**ข้อสังเกต**
- แจ้งเตือนระบบ Android ตอนปิดแอปยังไม่ทำ (ในเกมเท่านั้น) — AC ข้อนี้ผ่านครึ่งเดียว
- ยังไม่ gate auto-craft/ช่องสกิล/ช่องเพื่อน ด้วยห้องสมุด (รอ YK)
