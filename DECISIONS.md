# DECISIONS.md

Log การตัดสินใจของ Opus (Orchestrator/PM) — append-only

---

## D-001 (2026-07-16) — Advisor: Fable, approved by YK — Monorepo layout เป็นทางการ

**ปัญหา:** GAME_CONTRACT §2/§3 ฉบับ v1.1 ยังเป็น layout เก่า (`lib/` single-app) ขัดกับ header v1.1 เองและ MODE_PLUGIN_SPEC §2 ซึ่งทั้งคู่ระบุ monorepo

**คำตัดสิน:** ใช้ `packages/wt_core` + `packages/wt_mode_*` + `app/` เป็น source of truth

**เหตุผล:** จำเป็นต่อ acceptance ของ T-032 (เพิ่มโหมดโดยแก้ core = 0 ไฟล์)

**ผลกระทบ:** GAME_CONTRACT bump เป็น v1.2 (§2, §3 แก้ path ทั้งหมด) — แก้ T-001 / T-002 / T-004 ให้ scaffold/อ้างอิง path ใหม่
