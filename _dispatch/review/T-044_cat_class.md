# T-044: cat level + classes
Module: cat_class | Priority: P0 | Owner: Sonnet | Depends: T-007,T-033,T-003
> D-004 · spec: GDD v0.5 · contract v2.1

## Goal
เลเวล/EXP แมว + คลาสตาม GDD v0.5 §3: แมวฝึกหัด → เลือก 1 ใน 4 คลาสที่ Lv10 · สกิลช่อง 1/2/3 ปลดที่ Lv10/20/30 · ขั้นที่ 2 ที่ Lv40 (ระบบรองรับ, content v1.1) · ตัวคูณ stat/ความเร็วตี/ระยะ/หลบ/ดาเมจสกิลจาก `classes` ใน JSON · เปลี่ยนคลาสในขั้นเดียวกันได้ฟรีเมื่อไม่ได้สู้บอส

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
CatProgress.level / exp / gainExp(n) / Stream<LevelUp> · CatClass.current / available / choose(classId) / modifiers -> ClassModifiers · skillsUnlocked

## Acceptance Criteria
- [ ] ตัวคูณทุกตัวอ่านจาก JSON — ไม่มีตัวเลขคลาสในโค้ด
- [ ] เลือกคลาสก่อน Lv10 ไม่ได้ · เปลี่ยนคลาสระหว่างสู้บอสไม่ได้
- [ ] EXP จากออฟไลน์ใช้สูตรเดียวกับออนไลน์ (ผ่าน IncomeModel)
- [ ] save/restore เลเวล คลาส tier ครบ (Save v3 `cat`)
- [ ] test: ธนู ATK ตีธรรมดาแรงสุด · เมจ ดาเมจสกิลแรงสุด · โจร ตีถี่สุด + หลบสูงสุด · นักรบ HP/DEF สูงสุด (เทียบด้วย sim เดียวกัน)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## ส่งงาน (2026-10-19)
**ไฟล์**
- `packages/wt_core/lib/src/core/contracts/cat_class.dart` — `ICatProgress`, `ICatClass`, `CatLevelUp`, `ClassModifiers`, `CatState` (Save v3 `cat`: level/exp/class/tier)
- `packages/wt_core/lib/src/cat/` — `cat_rules.dart` (`CatRules.fromBalance`), `cat_progress.dart` (`CatProgress`), `cat_class.dart` (`CatClass` + `combatSpec()` + snapshot/restore), `cat.dart`
- barrel + `providers.dart`: `catRulesProvider` (override ตอน boot), `inBossFightProvider` (ค่าเริ่ม false — T-034 override), `catProgressProvider`, `catClassProvider`
- `idle_balance_v1.json`: `cat_level.ASSUMPTION_base_stats` (Lv1 HP 40 / ATK 6 / DEF 3 → พลัง 59 ≈ base_power 60), `ASSUMPTION_exp_per_kill_growth_per_page` 1.06, `classes.*.tier` (+ `from` สำหรับ tier 2) — balance sim ผลเดิม PASS (sim ยังไม่จำลองเลเวลแมว)

**Test** (`test/cat/cat_test.dart` +23 → รวม 91 เขียว · analyze 0 ทั้ง 3 package)
- data → fixed point (ตามกฎแปลงหน่วยใน T-007), EXP curve, พลัง Lv1, data พัง/tier 2 ไม่มี from → error
- gainExp: เลเวลขึ้น, กระโดดหลายเลเวลยิง `CatLevelUp` ครั้งเดียวต่อการเรียก, เลเวลสูงสุด exp = 0, ติดลบ throw
- คลาส: ก่อน Lv10 เลือกไม่ได้, เลือก 1 ใน 4, สลับฟรีใน tier, ระหว่างบอส throw, tier 2 จากคลาสแม่ที่ Lv40 (ข้อมูลทดสอบ), ช่องสกิล 0/1/2/3 (ฝึกหัด = 0 เสมอ)
- save: decode ตัวอย่าง Save v3, round-trip, ปฏิเสธ class/tier/level/exp ที่ไม่เข้ากับ data
- เทียบคลาสใน combat sim เดียวกัน (Lv30, 60 วิ): ดาเมจตีธรรมดา ธนู 876 > โจร 700 > นักรบ 420 > เมจ 336 · จำนวนครั้งตี โจร 100 · หลบ โจร 9 · นักรบอยู่ได้นานสุดกับมอนแรง · skill_dmg เมจสูงสุด

**ข้อสังเกต / หนี้**
- **AC EXP ออฟไลน์ทำได้ครึ่งเดียว:** `CatRules.expPerKill(page)` เป็นฟังก์ชันเดียวที่ทั้งออนไลน์/ออฟไลน์ต้องเรียก — T-034/T-035 ต้องส่ง EXP ผ่านตัวนี้ (ไม่ได้แตะ `IIncomeModel`/`RewardBundle` เพราะ loop กำลังจะคุยใหม่)
- **AC เมจ:** ตอนนี้เช็กได้แค่ตัวคูณ skill_dmg — ดาเมจสกิลจริงรอ T-008
- `LevelUp` ชื่อชนกับ `run_systems.dart` (เลเวลในโหมดท้าทาย) → ใช้ `CatLevelUp`
- **สูตร stat (YK เลือกแล้ว):** (ค่าเลเวล + อุปกรณ์) × ตัวคูณคลาส ใน `CatClass.combatSpec` — test ยืนยันว่าคลาสยังต่างกันเมื่ออุปกรณ์เป็นค่าส่วนใหญ่
- **ไม่มีเลเวลสูงสุด (YK):** `exp_curve` เป็นช่วง ต้น ×1.10 / กลาง Lv20–39 ×1.15 / ปลาย ×1.08 · EXP ต่อเลเวลเพดาน 2^53 กันล้น · ลบ `max_level` ออกจาก data
- การเติบโตต่อเลเวลแบบเส้นตรง (base × (1 + 2% × (L−1)))
