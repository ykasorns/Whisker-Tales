# T-034: idle loop — page progression, wave source, boss gate
Module: idle_loop | Priority: P0 | Owner: Sonnet | Depends: T-007,T-033,T-003
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
โหมดหลัก (core — ไม่ใช่ GameMode): เล่ม→บท→หน้า, คลื่นไม่รู้จบของหน้าที่ฟาร์ม, เลือกหน้าฟาร์ม (farm_min_power_ratio), ท้าบอสหน้า/บอสบท, รายได้ต่อคลื่น (ปลาทอง/ไหมพรม/ไข่) — curve ทั้งหมดจาก idle_balance_v1.json

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
IdleLoop.state / challengeBoss() / Stream<WaveCleared|BossResult> / IncomeModel.perWave(page)

## Acceptance Criteria
- [ ] P(n), boss mult, รายได้ต่อคลื่น ตรงกับสูตรใน JSON (test เทียบตาราง)
- [ ] แพ้บอส = ไม่เสียอะไร กลับไปฟาร์ม
- [ ] IncomeModel ใช้ร่วมกับ offline_reward (ฟังก์ชันเดียวกัน ไม่ copy)
- [ ] deterministic ตาม seed

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.3 (D-008, 2026-10-19) — spec: GDD v0.5.2 §9.1
- จำนวนคลื่นต่อหน้า + มอนต่อคลื่นสุ่มจาก seed ของหน้าตาม `pages` (ช่วงต่อบท + หน้ายาว 5/10 +2 คลื่น) — ฟังก์ชัน pure `pagePlan(book, page) → (waves, monstersPerWave[])` ให้ UI โชว์จุด ○○○ ได้ก่อนสู้
- ผ่านคลื่นครบ = ท้าบอสได้ · override `inBossFightProvider` (T-044) ให้คืนค่าจริง
- EXP ต่อมอน = `CatRules.expPerKill(page)` (T-044) — ใช้ทั้งออนไลน์และใน IncomeModel ของออฟไลน์ (ปิด AC EXP ออฟไลน์ของ T-044)
- เปิดจุดเชื่อม `onWaveCleared` / `onWalkBetweenWaves` ให้ T-048 (เหตุการณ์) — ห้ามเขียน logic เหตุการณ์ใน T-034

---
## ส่งงาน (2026-10-19)
**ไฟล์**
- `core/contracts/idle_loop.dart` — `PagePlan` (ใหม่), `WaveFailed` (ใหม่), `WaveCleared` + `waveIndex`/`exp`, `BossResult` + `exp` (named, default 0) · `IIncomeModel` + `perWaveMilli` / `forWaves` / `expForWaves` (เศษ เช่นไหมพรม 0.1/คลื่น ต้องสะสมเป็นหน่วยพัน ไม่งั้นปัดเป็น 0)
- `src/idle/` — `idle_rules.dart`, `page_plan.dart` (`pagePlan`, `mixSeed`), `income_model.dart`, `idle_loop.dart` (`IdleLoop`, `IdleHooks`, `IdlePhase`)
- `SeededRng` ย้าย `src/combat/` → `src/core/random/` (ใช้ร่วม combat + idle โดยไม่ import ข้าม module)
- providers: `idleRulesProvider`, `idleSeedProvider`, `catExtraStatsProvider` (gear/pets/บัฟ override), `incomeModelProvider`, `idleLoopProvider` (ส่ง EXP ให้ `catProgressProvider`), `inBossFightProvider` อ่านจาก loop จริง
- `idle_balance_v1.json`: `enemy` + hp_share 60%, ช่วงตีมอน/บอส · `pages` + chapters_per_book, เวลาเดิน/พัก, ถอยหน้าหลังแพ้ 3 ครั้ง, AUTO รอ 3 คลื่นหลังแพ้บอส, เวลาบอส 60 วิ · `income` + boss_exp_kills — sim ผลเดิม PASS

**Test** (`test/idle/` +17 → รวม 108 เขียว · analyze 0 ทั้ง 3 package)
- P(n), บอสหน้า/บอสบท, เลขเล่ม/บท/หน้า, รายได้ต่อคลื่นแบบหน่วยพัน
- pagePlan: เหมือนเดิมทุกครั้ง, อยู่ในช่วงของบท, หน้า 5/10 ยาว, ความยาวต่างกัน
- รายได้ออนไลน์รวม = `forWaves` ของออฟไลน์ (สูตรเดียว) · EXP ต่อคลื่น = มอนจริง × expPerKill
- บอส: เปิดหลังคลื่นครบ, ชนะ → หน้าใหม่ + รางวัล, แพ้ → ไม่เสียอะไร, AUTO ไต่หน้า, hook กัน AUTO ได้, AUTO รอ 3 คลื่นหลังแพ้
- แพ้คลื่นซ้ำ → ถอยหน้า · เลือกหน้าฟาร์ม ≤ หน้าหน้าสุด · hook ถูกเรียก · seed เดียวกัน + แบ่งเวลา 16/37/1000 ms → event เดียวกัน · providers ส่ง EXP จริง

**ข้อสังเกต / หนี้**
- ทุกการสู้เริ่ม HP เต็ม (ไม่ค้าง HP ข้ามคลื่น) — ถ้าอยากให้ค้างต้องตัดสินใจ design
- แมว Lv1 ไม่มีอุปกรณ์ ฟาร์มหน้า 1 ได้ (10 นาที → Lv6) แต่แพ้บอสหน้า 1 (พลัง 59 vs 150) → อุปกรณ์ชิ้นแรกจากการถักคือทางผ่าน · จูนรวมใน T-029
- รางวัล (ปลาทอง/ไหมพรม/ไข่) แค่ emit — กระเป๋าเงิน (T-021) เป็นคนรับ · save `idle` ตอนนี้กู้แค่ `cleared_page` (หน้าฟาร์ม = หน้าหน้าสุด)
- เปิด hook ให้ T-048 แล้ว: walk / wave cleared / boss ended (นับอายุผล) / canAutoChallenge (AUTO รอดีบัฟหมด) · บัฟเข้าทาง `catExtraStatsProvider` จนกว่า T-008 buff engine จะมา
- ปุ่มความเร็ว: ผู้เรียก `tick` คูณเวลาเอง (UI)

---
## ตรวจรับ (2026-10-23, Opus) → done
- ✓ สูตร P(n)/boss/รายได้: `idle_loop_test` · ✓ แพ้บอสไม่เสียอะไร · ✓ ใช้ IncomeModel เดียวกับออฟไลน์ ("waves pay the same as the offline formula") · ✓ deterministic
