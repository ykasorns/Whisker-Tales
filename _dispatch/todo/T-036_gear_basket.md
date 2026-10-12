# T-036: gear basket — craft, grade table, pity, compare, recycle, slot upgrade
Module: gear_basket | Priority: P0 | Owner: Sonnet | Depends: T-007,T-003
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
ตะกร้าไหมพรมแบบ 'ถักเอง' GDD v0.4 §3: เลือกช่อง → สุ่มเกรดตามตารางเลเวลตะกร้า + pity → affix จาก pool → เทียบกับของเดิม (ดาว ✨ เมื่อดีกว่าทุก base stat) → สวม/รีไซเคิล → EXP ตะกร้า · อัพเกรดช่อง (ไม่ผูกชิ้น)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
GearBasket.craft(slot|random) -> CraftResult / equip(id) / recycle(id) / upgradeSlot(slot) / gradeTable (สำหรับ UI โชว์อัตรา)

## Acceptance Criteria
- [ ] อัตราเกรดตรงตาราง JSON (chi-square test 100k ครั้ง)
- [ ] pity: ครบ N ครั้งได้ ≥ เกรดขั้นต่ำ แล้วรีเซ็ต
- [ ] isStrictlyBetter = ทุก base stat ≥ เดิม และไม่เท่ากันทั้งหมด
- [ ] เปลี่ยนชิ้นในช่อง ไม่เสียเลเวลช่อง
- [ ] ไม่มี path ไหนให้ไหมพรมจาก IAP (test เช็ค vocabulary reward)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
