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

---
## Amendment v2.1 (D-004, 2026-10-18)
ช่องอุปกรณ์ตาม GDD v0.5 §4.1: weapon, hat, shirt, shoes เริ่ม · scarf/gloves/bell/bag ปลดตาม `slot_unlocks` · ถักได้เฉพาะช่องที่ปลด · ของแต่ละชิ้นมี `style_id` (ส่งให้ `wardrobe` ปลด) · affix 3 ชั้น (หลัก/รอง/พิเศษ) · "ดีกว่า" สำหรับระบบอัตโนมัติ = PowerScore ของชิ้นสูงกว่า

---
## ส่งงาน (2026-10-19) — ทำคู่กับ T-037
**ไฟล์**
- `core/contracts/gear_basket.dart` — `GearSlot` เป็น 8 ช่อง v0.5 (weapon/hat/shirt/shoes/scarf/gloves/bell/bag), `GearItem` (stats, tier, styleId, isStrictlyBetterThan, JSON), `CraftResult` + item/isNewStyle, `AutoCraftMode` stash/equip, `AutoCraftRule` = Save v3 `auto_craft` {on, better}
- `core/contracts/wallet.dart` + `core/wallet/memory_wallet.dart` — `IWallet` (T-021 จะเป็นเจ้าของจริง) · `SeededRng.fromState/state` (เซฟลำดับสุ่มต่อได้)
- `src/gear/` — `gear_rules.dart`, `gear_basket.dart`, `auto_craft.dart`
- `design/data/gear_slots.json` (ใหม่) — สัดส่วนพลังต่อช่อง + affix pool 3 ชั้น · `idle_balance_v1.json` gear + random_slot_exp_bonus_pct, auto_craft_interval_ms (1000 ให้ทันอนิเมชันก้อนไหมพรม)
- providers: `walletProvider`, `gearRulesProvider`, `gearBasketProvider`, `autoCraftProvider` · `catExtraStatsProvider` = ค่าอุปกรณ์ที่สวม · รางวัลจาก idle loop เข้า wallet

**Test** (`test/gear/` +20 → รวม 128 · analyze 0 ทั้ง 3 package · sim PASS)
- อัตราเกรด chi-square 100k ครั้ง · pity ทุก 30 ครั้ง · สุ่มช่องเฉพาะที่ปลด · ช่องล็อก/ไม่มีไหมพรม throw
- ของ: สัดส่วน stat ตามช่อง, จำนวน affix ตามเกรด, affix พิเศษเฉพาะม่วงขึ้นไป, styleId ตาม tier
- ✨ ดีกว่าทุก stat · สวมแล้วของเก่ารีไซเคิล · เลเวลช่องไม่หายเมื่อเปลี่ยนของ · สุ่มช่อง EXP +50% · ตะกร้าเลเวลขึ้นแล้วตารางดีขึ้น · ไม่มี path ไหนให้ไหมพรม · save/restore แล้วสุ่มต่อเหมือนเดิม
- ทั้งระบบ: ฟาร์ม → ถักอัตโนมัติ → ชนะบอสหน้า 1 ภายใน 30 นาทีเกม

**ข้อสังเกต / หนี้**
- **บาลานซ์ (T-029):** แมวไม่มีของแพ้บอสหน้า 1 จนได้ของ ~7 ชิ้น · ไหมพรม 0.1/คลื่น → ชิ้นละ ~4 นาที → ชนะบอสแรกที่ ~20 นาที (เป้า GDD 3–5 นาที/หน้า) — เสนอ: ไหมพรมเริ่มต้น + ไหมพรมจากบอส/คลื่นแรก ๆ
- ของที่ถักแล้วยังไม่ตัดสินใจ (pending) ไม่ถูกเซฟ
- `isNewStyle` ใช้ set ในหน่วยความจำจนกว่า T-045 wardrobe จะต่อ `unlockStyle`
- **อัปเดต D-011:** ไหมพรมเริ่มต้น 10 + ไหมพรม/บอสช่วงบท 1 ง่ายขึ้น + สูตรพลังใหม่ (affix เป็น % ของพลังหลัก) → บอสหน้า 1–4 ภายใน ~5 นาที · test ทั้งระบบเช็กผ่าน ≥ 4 หน้าใน 30 นาที

---
## ตรวจรับ (2026-10-23, Opus) → done
- ✓ chi-square 100k · pity · strictly better · ช่องไม่เสียเลเวล · ไหมพรมไม่มีทางจาก IAP: `gear_test.dart`
- หนี้ "pending ไม่ถูกเซฟ" ปิดแล้ว: "knits still pending when the app closes are saved, settled on load"
