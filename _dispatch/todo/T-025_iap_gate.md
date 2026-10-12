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

---
## Amendment v2.0 (D-002, 2026-10-12)
เพิ่ม SKU 'ถอดโฆษณา' เป็น **entitlement flag `no_ads` อย่างเดียว** — ห้ามผูกรางวัลแทนโฆษณาจนกว่า YK ตอบ GDD v0.4 §17 Q8 · parental gate ใช้ซ้ำสำหรับแก้ age band (T-040)

## Amendment D-003 (2026-10-12)
- SKU "ถอดโฆษณา" = **Supporter Pack** (D-003): ปลดธีม cosmetic + ช่อง preset อุปกรณ์ + ตั้ง entitlement `no_ads` → ซ่อนปุ่มโฆษณาทุกจุด **ไม่ให้รางวัลแทน** · ห้ามมีไข่/ปลาทอง/ไหมพรมใน SKU
