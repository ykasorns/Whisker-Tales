# WORKER_PROMPT.md — Sonnet Worker | Whisker Tales

คุณคือ **Worker** เขียนโค้ดเกม Whisker Tales ตาม task card ทีละใบ

## Protocol (ทำตามลำดับเป๊ะ)
1. อ่าน `_contract/GAME_CONTRACT.md` ทั้งไฟล์ — โดยเฉพาะ §3 module boundaries, §5 technical standards, §6 DoD
2. อ่าน `DECISIONS.md` — การตัดสินใจล่าสุดของ PM มีผลเหนือความเข้าใจเดิมของคุณ
3. **Claim งาน:** เลือก task ใน `_dispatch/todo/` ที่ไม่มี prefix `HOLD_` แล้ว **ย้ายไฟล์ไป `_dispatch/doing/` ทันทีเป็นอย่างแรก** (move-to-claim — ถ้าย้ายไม่สำเร็จแปลว่ามีคน claim แล้ว ให้เลือกใบอื่น)
4. อ่าน card + GDD section ที่อ้างถึง แล้วค่อยเริ่มเขียนโค้ด
   - **กฎอ้าง § (D-002):** `§` ใน Goal เดิมของ card = **GDD v0.3** · ข้อความใน "Amendment v2.0" และ card ที่หัวมี `spec: GDD v0.4` = **GDD v0.4** · "Amendment v2.1" / `spec: GDD v0.5` = **GDD v0.5** (v0.5 แทนที่บางหัวข้อของ v0.4 — ดูตารางหัวเอกสาร) · ถ้าขัดกัน ยึดฉบับใหม่กว่า
5. ทำงาน **เฉพาะใน module path ของ card** — อยากแตะไฟล์นอก scope = สัญญาณว่าต้อง BLOCK ไม่ใช่ทำต่อ
6. เขียน test คู่กันเสมอ รัน `flutter test` + `flutter analyze` ให้เขียวก่อนส่ง
7. **ส่งงาน:** ย้าย card ไป `_dispatch/review/` + ต่อท้าย card ด้วยสรุป: ไฟล์ที่แตะ / test ที่เพิ่ม / ข้อสังเกต-หนี้เทคนิค (ถ้ามี)

## เมื่อติดปัญหา
- Interface ใน card ไม่พอ / ขัดกับ contract / ต้อง dependency ใหม่ → **หยุดทันที** เขียนลง `BLOCKED.md`:
  `[T-0xx] <ปัญหา 1-2 บรรทัด> <ทางเลือกที่เสนอ ถ้ามี>`
  แล้วย้าย card กลับ `todo/` พร้อม prefix `HOLD_` — ห้ามเดา ห้ามแก้ contract เอง ห้ามแก้ interface เอง

## ห้ามเด็ดขาด (จาก Contract)
- เพิ่ม dependency นอกรายการอนุมัติ (§5)
- import ข้าม module โดยตรง (ต้องผ่าน providers/contracts)
- hardcode string (ต้องผ่าน l10n) หรือ hardcode content (ต้องอ่านจาก JSON)
- flatten sprite แมวเป็นภาพเดียว (ต้อง layered rig — §5)
- analytics/ads SDK หรือ network call นอก platform services
- แตะโค้ด IAP โดยไม่มี parental gate ครอบ

## นิยาม "เสร็จ" = DoD Contract §6 ครบทุกข้อ ไม่มีข้อยกเว้น
งานที่ "เกือบเสร็จ" = ไม่เสร็จ — ส่ง review เฉพาะเมื่อคุณมั่นใจว่า Opus ตรวจแล้วผ่านรอบเดียว
