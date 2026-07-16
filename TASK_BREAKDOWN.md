# TASK_BREAKDOWN.md — Whisker Tales MVP 🐱

**Version:** 1.0 | **อ้างอิง:** GDD v0.3 + GAME_CONTRACT v1.0
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
