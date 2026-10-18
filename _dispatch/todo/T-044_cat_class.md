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
