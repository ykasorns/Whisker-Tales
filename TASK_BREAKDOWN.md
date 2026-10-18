# TASK_BREAKDOWN.md — Whisker Tales MVP 🐱

**Version:** 2.0 | **อ้างอิง:** GDD v0.4 + GAME_CONTRACT v2.0 (ดู Amendment v2.0 ท้ายไฟล์)
**รวม:** 30 task cards ใน `_dispatch/todo/` | Owner default = Sonnet (ยกเว้นระบุ)

---

## Dependency Graph (ภาพรวม)

```
Phase 0 Foundation          Phase 1 Core Systems         Phase 2 UI
─────────────────           ────────────────────         ─────────────────
T-001 scaffold ──┬─ T-002 contracts ─┬─ T-005 RunMgr ──── T-006 encounter ─┐
                 │                   ├─ T-007 combat ─┬─ T-008 skills      │
T-004 l10n ──────┤                   │                └──── T-009 dodge    │
                 │  T-003 loader ────┼─ T-010 relic ────── T-011 synergy   │
                 │       │           └─ T-012 talent ───── T-013 t-resolve │
                 │       └─ T-026 content JSON (Opus)                      │
                 │                                                         │
                 └─ T-014 panel shell ─┬─ T-015 HUD                        │
                                       ├─ T-016 node map ◄────────────────┘
                                       ├─ T-017 combat panel ◄─ T-008,T-009
                                       ├─ T-018 card pick ◄─ T-011,T-012
                                       ├─ T-019 event/shop panels
                                       └─ T-020 village ◄─ T-021

Phase 3 Services                       Phase 4 Integration
────────────────                       ───────────────────
T-022 save local ── T-023 cloud        T-027 art integration + rig
T-021 meta ──────── T-025 IAP+gate     T-028 boss fight
T-024 audio                            T-029 balancing ── T-030 store ready
```

## ลำดับที่แนะนำ & งานขนาน

| Wave | Tasks (ขนานได้ — คนละ module) |
|---|---|
| 1 | T-001 |
| 2 | T-002, T-004 |
| 3 | T-003, T-014, T-022 |
| 4 | T-005, T-007, T-026(Opus), T-024 |
| 5 | T-006, T-008, T-010, T-012, T-021, T-023 |
| 6 | T-009, T-011, T-013, T-015, T-019 |
| 7 | T-016, T-017, T-018, T-020, T-025, T-027 |
| 8 | T-028 |
| 9 | T-029 → T-030 |

## Milestone Gates

| Gate | เงื่อนไข | ความหมาย |
|---|---|---|
| 1 — Engine Alive | T-001–008, T-022 | สู้มอนได้ใน test ไม่มี UI |
| 2 — Playable Loop | + T-009–019, T-026 | เล่นจบ run บนเครื่องจริง |
| 3 — Feature Complete | ทุกใบยกเว้น T-029/030 | พร้อม balancing + playtest เด็กจริง |
| 4 — Store Ready | T-030 | พร้อม submit 2 stores |

## Track คู่ขนาน: Art Pipeline (นอก dispatch โค้ด)

| ลำดับ | งาน | อ้างอิง |
|---|---|---|
| A-1 | gen Style Anchor Sheet (แบบ B) → YK review → ล็อก ANCHOR v1 | ART_PROMPT_BIBLE ท้ายไฟล์ |
| A-2 | ตัวละครโมจิครบ rig layers + boiling frames | Bible §4.1, §5 |
| A-3 | มอน 5 + boss | Bible §4.2 |
| A-4 | ไอคอน relic 15 + talent 9 + potion 4 | Bible §4.3 |
| A-5 | การ์ด + UI ปุ่มครบ | Bible §4.4, §4.7 |
| A-6 | ฉากป่าดินสอสี parallax 4 ชั้น + effects | Bible §4.5, §4.6 |

A-1 ต้องเสร็จก่อน T-027 / A-2–A-6 ทยอยส่งเข้า `assets/raw/` → QA checklist → `assets/game/`

## วิธี Deploy Pack นี้

1. วางทั้ง folder ลงโครง repo ตาม GAME_CONTRACT §2 (`_contract/`, `_dispatch/todo/` ฯลฯ)
2. เปิด session Opus ด้วย `PM_PROMPT.md` — Opus จะ HOLD_ task ที่ dependency ยังไม่ครบเอง
3. เปิด Sonnet workers ด้วย `WORKER_PROMPT.md` (ขนานได้ตามตาราง Wave — คนละ module)
4. YK รับรายงานเฉพาะตอน Gate หรือมี escalation ถึง Advisor


---

## Amendment v1.1 — Game Mode Plugin Architecture

- อ่าน `_contract/MODE_PLUGIN_SPEC.md` ก่อนทำ T-002/T-005/T-020/T-022 (มี Amendment ต่อท้าย card แล้ว)
- Task ใหม่: **T-031** (mode framework + story เป็น plugin — เข้า Wave 7.5 หลัง T-020) และ **T-032** (endless vertical slice, enabled:false — เข้า Wave 8 ขนานกับ T-028)
- Gate 3 "Feature Complete" ขยับเป็น: รวม T-031 (T-032 เป็น optional ก่อน launch แต่ต้องเสร็จก่อน v1.2)
- `design/balance/balance_seed.json` = ค่าตั้งต้นจาก prototype v0.2 ที่ YK เล่นแล้วอนุมัติ feel — T-026 ใช้ไฟล์นี้เป็นฐาน T-029 จูนต่อจากค่านี้

---

## Amendment v2.0 — Idle RPG Pivot (D-002, 2026-10-12)

อ้างอิง: GDD v0.4 + GAME_CONTRACT v2.0 · research: `design/research/lom_analysis.md` · balance: `design/balance/idle_balance_v1.json` + `tools/balance_sim`

**เขียนใหม่:** T-007 (deterministic sim + damage pipeline), T-008 (buff engine + skills)
**Amendment ต่อท้าย card:** T-005, T-006, T-010, T-011, T-012, T-013, T-020, T-021, T-022, T-025, T-026, T-029, T-032
**ไม่แตะ:** T-001 (อยู่ใน doing)

**Task ใหม่:**
| Task | Module | Depends | Wave |
|---|---|---|---|
| T-033 GameClock + daily reset + v2 contracts | core_loop | T-002 | 3 |
| T-040 age screen | age_gate | T-033, T-022 | 4 |
| T-039 ads (AdService + fake + caps) | ads | T-033, T-040, T-022 | 5 |
| T-034 idle loop | idle_loop | T-007, T-033, T-003 | 5 |
| T-036 gear basket | gear_basket | T-007, T-003 | 5 |
| T-035 offline reward | offline_reward | T-034, T-033, T-022 | 6 |
| T-037 auto-craft | gear_basket | T-036 | 6 |
| T-038 pets + hatch | pets | T-007, T-033, T-039 | 6 |
| T-041 research | research | T-033, T-039, T-003 | 6 |
| T-043 content JSON v2 (Opus) | design-data | T-003, T-008 | 6 |
| T-042 idle UI panels | ui_panel | T-014, T-034, T-035, T-036, T-038, T-041 | 7 |

**Gate ปรับ:**
| Gate | เงื่อนไขใหม่ |
|---|---|
| 1 — Engine Alive | T-001–T-008, T-022, T-033 → sim สู้ deterministic + buff engine ใน test |
| 2 — Idle Loop Playable | + T-034–T-041, T-043, T-042 → ฟาร์ม/ถัก/ฟัก/วิจัย/ออฟไลน์ บนเครื่องจริง |
| 3 — Feature Complete | + โหมดนิทานผจญภัย (T-005, T-006, T-009–T-019, T-026, T-028, T-031) + T-020, T-021, T-023–T-025, T-027 |
| 4 — Store Ready | T-029 (sim + playtest ผ่าน) → T-030 (+ Privacy/Data Safety/ads disclosure ใหม่) |

**รอ YK:** Q7 จุดโฆษณาเพิ่ม · Q8 รูปแบบ IAP ถอดโฆษณา (GDD v0.4 §17) — ไม่บล็อก wave ใด (T-025/T-039 ทำแบบ flag ไว้)

---

## Amendment v2.1 — Classes · Wardrobe · Idle-only (D-004, 2026-10-18)

อ้างอิง: GDD v0.5 + CONTRACT v2.1 · แผน: `design/proposals/v0.5_plan.md`

- **ยกเลิก:** T-009 (→ `HOLD_T-009`, ไม่มีปุ่มหลบ)
- **เขียนใหม่:** T-027 → rig runtime (P0, module `rig`)
- **Amendment:** T-007, T-008, T-017, T-032, T-036, T-037, T-042, T-043
- **ใหม่:**

| Task | Module | Depends | Wave |
|---|---|---|---|
| T-046 rig prototype ในเว็บ (Claude) | design-data | ภาพโมจิสองขา | ทันทีที่ได้ภาพ |
| T-044 cat level + classes | cat_class | T-007, T-033, T-003 | 6 |
| T-045 wardrobe | wardrobe | T-036, T-022 | 7 |
| T-027 rig runtime | rig | T-001, T-046 | 7 |
| HOLD_T-047 dungeon | mode_dungeon | T-031, T-044, T-045 | v1.1 |

- **Gate 2 (Idle Loop Playable)** เพิ่ม: T-044, T-027 (โมจิประกอบจาก rig + เลือกคลาสได้)
