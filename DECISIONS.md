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
