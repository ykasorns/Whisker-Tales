# DECISIONS.md

Log การตัดสินใจของ Opus (Orchestrator/PM) — append-only

---

## D-001 (2026-07-16) — Advisor: Fable, approved by YK — Monorepo layout เป็นทางการ

**ปัญหา:** GAME_CONTRACT §2/§3 ฉบับ v1.1 ยังเป็น layout เก่า (`lib/` single-app) ขัดกับ header v1.1 เองและ MODE_PLUGIN_SPEC §2 ซึ่งทั้งคู่ระบุ monorepo

**คำตัดสิน:** ใช้ `packages/wt_core` + `packages/wt_mode_*` + `app/` เป็น source of truth

**เหตุผล:** จำเป็นต่อ acceptance ของ T-032 (เพิ่มโหมดโดยแก้ core = 0 ไฟล์)

**ผลกระทบ:** GAME_CONTRACT bump เป็น v1.2 (§2, §3 แก้ path ทั้งหมด) — แก้ T-001 / T-002 / T-004 ให้ scaffold/อ้างอิง path ใหม่

---

## D-002 (2026-10-12) — YK approved · Advisor (Fable) review pending — Pivot เป็น Idle RPG (GDD v0.4 + CONTRACT v2.0)

**ที่มา:** YK สั่งวิเคราะห์ Legend of Mushroom ด้วย REA แล้ว pivot (research: `design/research/lom_analysis.md`) — YK ตอบ Q0–Q8 วันที่ 2026-10-12

**คำตัดสิน:**
1. Spec หลัก = `_contract/GDD_WhiskerTales_v0.4.md` · v0.3 = superseded ใช้เป็น spec โหมดนิทานผจญภัยเท่านั้น
2. ตะกร้าไหมพรมแบบ deterministic "ถักเอง" (Q0=ข) · โหมดผจญภัยอยู่ใน MVP (Q1) · research ใช้เวลาจริง + ad ลดเวลา (Q2) · offline cap 8 ชม. +10 นาที/เลเวล (Q3) · auto-craft ใน MVP (Q4) · ตัวเลขใช้ curve ของเราเอง ไม่ใช้ค่าของ LoM (Q5)
3. **ข้อห้าม v0.3 §12 ที่เปลี่ยน:** ads → อนุญาต rewarded เท่านั้น (≤8/วัน, cap บังคับที่ module `ads`) · loot box → gacha เพื่อนสัตว์ด้วยทรัพยากรในเกมเท่านั้น (ไข่ดรอป + ad 3/วัน + ปลาทอง 5/วันราคา ×1.5) — **ไข่/ปลาทองห้ามขายด้วยเงินจริงถาวร**
4. คงเด็กเป็นกลุ่มเป้าหมาย (Q6) → age screen + non-personalized ads สำหรับ <13 + ไม่ขอ ATT + Families-certified ad SDK เท่านั้น
5. สถาปัตยกรรม: โหมด idle หลัก = core module `idle_loop` (ไม่ใช่ GameMode — run model ไม่รองรับฟาร์มต่อเนื่อง/ออฟไลน์) · story/endless ยังเป็น plugin · T-032 คงไว้ P2
6. CONTRACT v2.0: module ใหม่ 7 ตัว, combat = deterministic sim + buff engine, Save v3 + conflict rule (cleared_page → power → updated_at) + กฎนาฬิกา, `tools/balance_sim`
7. Balance seed = `design/balance/idle_balance_v1.json` · sim ผ่าน 2 เป้า (เล่ม 1 = 15.6 วัน, gap no-ads 0.2%) แต่ **ไวต่อค่ามาก + โฆษณาแทบไม่มีผล** → T-029 ต้องจูนซ้ำหลังมี combat engine

**ยังเปิด (ห้าม implement ส่วนที่ขึ้นกับคำตอบ):** Q7 จุดโฆษณาเพิ่ม (ข้อเสนอ GDD §17 — ทุกจุด `enabled:false` ใน JSON) · Q8 รูปแบบ IAP ถอดโฆษณา (ก/ข/ค — ข ชน §6.2/§7) → T-025 ทำ entitlement `no_ads` เป็น flag อย่างเดียว

**ผลกระทบ task:** แก้ T-007, T-008 (เขียนใหม่) · amendment T-005, T-006, T-010–T-013, T-020, T-021, T-022, T-025, T-026, T-029, T-032 · ใหม่ T-033–T-043 (ดู TASK_BREAKDOWN Amendment v2.0) · T-001 (doing) ไม่แตะ

---

## D-003 (2026-10-12) — YK — ปิด Q7 / Q8 ของ GDD v0.4

1. **Q7:** เพิ่ม rewarded ad 2 จุด — 🎁 ของขวัญประจำวัน (1/วัน, ปลาทอง = รายได้ 60 นาที) + 🧶 ไหมพรมพิเศษ (2/วัน, ไหมพรม = รายได้ 30 นาที) · cap รวมเพิ่มจาก 8 → **10/วัน** · ❌ ไม่ทำ x2 ออฟไลน์ (sim: gap 38.6% เกินเพดาน)
2. **Q8:** IAP ถอดโฆษณา = **(ค) Supporter Pack** — cosmetic + ซ่อนปุ่มโฆษณาทุกจุด (`no_ads_behavior: hide`) **ไม่ให้รางวัลแทน** + โบนัสไม่สุ่ม/ไม่เร่ง → ไม่มี paid loot box / paid skip
3. sim หลังเปลี่ยน (20 seeds): full_ads 14.8 วัน, no_ads 15.6 วัน, gap 5.8% → ผ่านทั้ง 2 เป้า (ยังต้องจูนซ้ำใน T-029)
4. ไฟล์: `idle_balance_v1.json` (placements enabled + cap 10 + no_ads_behavior hide), GDD v0.4 §10/§16/§17, T-025, T-039

---

## D-004 (2026-10-18) — YK approved · Advisor (Fable) review pending — GDD v0.5: คลาส · ตู้เสื้อผ้า · idle ล้วน

**ที่มา:** YK ขอแมวสองขา + ชุด/อาวุธที่มองเห็นได้ + stat ลึกขึ้น + ตัดปุ่มหลบ + ดันเจี้ยน (แผน: `design/proposals/v0.5_plan.md`) แล้วตอบคำถาม 2026-10-18

**คำตัดสิน:**
1. Spec = `GDD_WhiskerTales_v0.5.md` แทนที่บางหัวข้อของ v0.4 (ตารางหัวเอกสาร) · CONTRACT v2.1
2. **Idle ล้วน:** ไม่มีปุ่มหลบ/แตะสกิล · หลบเป็น stat · ปุ่มความเร็ว x1 / x1.5 (ผ่านหน้า 5) / x2 (ผ่านหน้า 10) · ปุ่มท้าบอสเป็นหน้าบอสกลางบน
3. **โมจิสองขา + rig 10 ชิ้น** — rig runtime เป็น module ใหม่ `rig` (P0) · ทดสอบ rig ในเว็บต้นแบบก่อนวาดอุปกรณ์จำนวนมาก
4. **เลเวลแมว + คลาส (YK Q2):** เลือกคลาสแรกที่ Lv10 จาก 4 คลาส (นักรบ/โจร/ธนู/เมจ) · ขั้นที่ 2 ที่ Lv40 (content v1.1) · คลาสละ 3 สกิลร่ายเอง · เปลี่ยนคลาสในขั้นเดียวกันได้ฟรี — module ใหม่ `cat_class`
5. **ตู้เสื้อผ้า (YK Q3):** หน้าตาแยกจากพลัง ปลดแบบจากของที่ถักได้ — module ใหม่ `wardrobe`
6. **ช่องอุปกรณ์ (YK Q4):** 8 ช่อง เริ่ม 4 (อาวุธ หมวก เสื้อ รองเท้า) ปลดเพิ่มที่หน้า 5/10/20/30 (v1.1 ปลดจากดันเจี้ยนได้ด้วย) · "ของเล่น" → อาวุธ · "ปลอกแขน" → ถุงมือ
7. **ถักอัตโนมัติ:** เปิด/ปิด + "ของดีกว่า: เก็บรอเลือก / ใส่ทันที" · ของอ่อนกว่ารีไซเคิลเอง · "ดีกว่า" = พลังรวมสูงกว่า
8. **Stat 3 ชั้น:** หลัก / รอง (คู่ anti-stat) / พิเศษ
9. **โหมดนิทานผจญภัย → "ท้าทายนิทาน" (YK Q1)** — ด่านท้าทายตามเนื้อเรื่อง ยังเป็น `wt_mode_story`
10. **ดันเจี้ยน = v1.1** (YK ไม่ได้ตอบ Q5 — ใช้ข้อเสนอ เปลี่ยนได้) · save/stat ออกแบบเผื่อแล้ว

**ผลกระทบ:** ภาพโมจิ 35 เฟรมเดิมต้อง gen ใหม่ (มอน/บอส/ไอคอนใช้ต่อได้) · T-009 ยกเลิก · T-027 → rig runtime P0 · amend T-008, T-017, T-036, T-037, T-042, T-043 · ใหม่ T-044 (cat_class), T-045 (wardrobe), T-046 (rig prototype ในเว็บ), T-047 (ดันเจี้ยน — HOLD v1.1)

---

## D-005 (2026-10-18) — YK — โมจิใช้ท่าเต็มตัว + อุปกรณ์ติดตามจุดยึด (แบบ A + B) แทน rig

**ที่มา:** T-046 ทดสอบ rig จากชิ้นส่วนที่ AI วาดในเว็บต้นแบบ — ประกอบได้ไม่มีรอยแหว่ง แต่ YK เห็นว่าดูแปลก/แข็ง (ไม่มีข้อศอก/เข่า, ลำตัวรอบแรกเป็นมุมหน้าตรง) · ท่าเต็มตัวที่ gen ทั้งตัวดูเป็นธรรมชาติกว่ามาก · ทดสอบแบบ A (ท่าเต็มตัว + อุปกรณ์บนจุดยึด) ในเว็บต้นแบบแล้ว ใช้ได้ทุกคลาส

**คำตัดสิน:**
1. Animation โมจิ = frame animation ท่าเต็มตัว 13 เฟรม (ยืน, เดิน 3, โจมตีมือเปล่า 5, หลบ, เจ็บ, ชนะ, นอน)
2. อุปกรณ์ที่เห็นบนตัว 4 ช่อง: อาวุธ (+ โล่/มีดเล่ม 2), หมวก, ผ้าพันคอ, กระเป๋า — วางตามจุดยึดต่อเฟรม (`design/art/anchors_mochi.json`) · ภาพเดียวต่อแบบใช้ได้ทุกท่า
3. เสื้อ รองเท้า ถุงมือ กระดิ่ง = ไอคอน + พลัง (ไม่แสดงบนตัว) · ชุดทั้งตัวใช้ **skin** (แบบ B) — MVP: skin ฐาน + 1
4. module `rig` → `avatar` (CONTRACT v2.2) · T-027 เขียนใหม่ · `rig_mochi.json` เก็บไว้เป็นทางเลือก
5. GDD v0.5 → 0.5.1 (§2, §4.1, §4.2)

**ผลกระทบ:** T-027 rewrite · T-045 amend (skin + ช่องที่ไม่เห็นบนตัว) · T-046 ปิด (ผลทดสอบ) · assetlist: ชิ้นอุปกรณ์บนตัวลดลง (ไม่ต้องวาดเสื้อ/รองเท้า/ถุงมือให้พอดีตัว) + skin ละ 13 เฟรม

---

## D-006 (2026-10-19) — Opus — combat engine (T-007): ข้อมูล + โครง type

**ที่มา:** T-007 ต้องการค่าทุกตัวจาก data แต่ floor/cap/น้ำหนักพลังมีแค่ใน GDD v0.4 §4.2/§15.2 ยังไม่มีใน JSON · module อื่น (`cat_class`, `gear_basket`, `idle_loop`, UI) ต้องใช้ StatBlock/event โดยห้าม import `combat` ตรง

**คำตัดสิน:**
1. เพิ่ม section `combat` ใน `idle_balance_v1.json` (หน่วย % → โค้ดแปลงเป็น basis point ตอนโหลด) · ค่าที่ GDD ยังไม่กำหนดเป็น `ASSUMPTION_`: แรงคริฐาน 150%, cap ดูดเลือด 30% / ฟื้นเลือด 5% / ความเร็วตี 100% / ลดคูลดาวน์ 50%, มึน 1000 ms, รอบฟื้นเลือด 1000 ms — จูนใน T-029
2. Type ร่วม (`Attribute`, `StatBlock`, `CombatUnitSpec`, `CombatSetup` เป็น class จริง, event ทั้งหมด) อยู่ใน `core/contracts/combat.dart` · engine/rules/RNG/PowerScore อยู่ใน `src/combat/` · ต่อผ่าน `providers.dart` (`combatRulesProvider` override ตอน boot)
3. `ICombatEngine.useSkill` คงไว้เป็น no-op ตาม D-004 (ไม่มี input ผู้เล่น) — T-008 ตัดสินว่าจะเปลี่ยนเป็น auto-cast อย่างไร
4. Sim ไม่มีระยะทาง: melee/ranged เป็นข้อมูลสำหรับ render เท่านั้น
