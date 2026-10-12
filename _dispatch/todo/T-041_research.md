# T-041: research — owl library tree, timers, queue, ad speed-up
Module: research | Priority: P0 | Owner: Sonnet | Depends: T-033,T-039,T-003
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
ห้องสมุดนกฮูก GDD v0.4 §7: tree + prerequisite, ราคา/เวลาโตตามเลเวล (JSON), คิว 1 (ปลดคิว 2 ใน tree), node `offline_cap` (+10 นาที/เลเวล), node ปลดฟีเจอร์ · ad ลดเวลา −max(30 นาที, 25% ที่เหลือ) ≤5/วัน ผ่าน AdService

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
Research.start(nodeId) / speedUpWithAd() / Stream<ResearchCompleted> / levels

## Acceptance Criteria
- [ ] ends_at เทียบกับ GameClock.effectiveNow (ย้อนนาฬิกาไม่ทำให้งานถอย)
- [ ] ไม่มี path เร่งด้วยเงินจริง/IAP
- [ ] แจ้งเตือนเฉพาะ 'วิจัยเสร็จ' และปิดได้ใน settings
- [ ] เวลา/ราคาตรงสูตร JSON

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
