# T-025: IAP + parental gate
Module: iap_gate | Priority: P1 | Owner: Sonnet | Depends: T-021,T-022

## Goal
parental gate (โจทย์สุ่มใหม่ทุกครั้ง เด็กเล็กผ่านไม่ได้) + in_app_purchase cosmetic 3 SKU + restore purchases — GDD §12

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
IapService.purchase(sku) / ParentalGate.challenge() -> bool

## Acceptance Criteria
- [ ] เข้าหน้าซื้อโดยไม่ผ่าน gate = เป็นไปไม่ได้ (test ทุก entry point)
- [ ] restore ทำงานทั้ง 2 platform
- [ ] ไม่มี SKU ที่กระทบ gameplay

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
