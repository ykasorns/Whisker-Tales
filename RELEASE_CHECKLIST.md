# Whisker Tales — Release checklist (Google Play)

T-030 / D-035. ฝั่งโค้ดพร้อมแล้ว ทุกอย่างในไฟล์นี้คือ **สิ่งที่ต้องใช้บัญชีของ YK** หรือ**ต้องลองบนมือถือจริง** ซึ่ง Claude ทำแทนไม่ได้ · ไม่ใช่คำปรึกษากฎหมาย — ยืนยัน policy ปัจจุบันของ Play อีกครั้งในวันส่ง

---

## 1. ตัดสินใจก่อนอัปโหลดครั้งแรก (เปลี่ยนทีหลังไม่ได้)

- [ ] **Package name** ตอนนี้ `com.whiskertales.whisker_tales` (`app/android/app/build.gradle.kts → applicationId`) — อัปโหลดครั้งแรกแล้วเปลี่ยนไม่ได้อีก ถ้าอยากได้ชื่ออื่น (เช่น `com.<ชื่อคุณ>.whiskertales`) บอก Claude ก่อน
- [ ] ชื่อผู้พัฒนาที่จะโชว์ในร้าน + อีเมลติดต่อ (ใช้ในนโยบายความเป็นส่วนตัวด้วย)

## 2. คีย์และรหัส (ห้าม commit — `.gitignore` กันไว้แล้ว)

- [ ] **Upload keystore** — สร้างครั้งเดียว เก็บไว้ 2 ที่ (ทำหายแล้วต้องขอ Google รีเซ็ต):
  ```bash
  keytool -genkey -v -keystore ~/whisker-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
  แล้วสร้าง `app/android/key.properties`:
  ```
  storePassword=…
  keyPassword=…
  keyAlias=upload
  storeFile=/Users/kolupy/whisker-upload.jks
  ```
  ใช้ **Play App Signing** (ค่าเริ่มต้นของ Play) — คีย์นี้เป็นแค่ upload key
- [ ] **AdMob**: สร้างบัญชี → Add app (Android, ยังไม่อยู่ใน store ก็ได้) → สร้าง ad unit แบบ **Rewarded** หนึ่งอัน
  - ใน AdMob → app settings: ตั้ง **"Designed for families / child-directed"** ตามกลุ่มเป้าหมายที่เลือกในข้อ 4 · Blocking controls → max ad content rating **G**
  - ใส่ `admobAppId=ca-app-pub-…~…` ใน `app/android/gradle.properties`
  - ตอน build: `ADMOB_REWARDED_ID=ca-app-pub-…/… scripts/build_release.sh`
  - ⚠️ ระหว่างทดสอบบนเครื่องตัวเอง **ห้ามกดโฆษณาจริงของตัวเอง** (บัญชีโดนแบน) — ใช้ build ที่ยังเป็นรหัสทดสอบ หรือเพิ่มเครื่องเป็น test device ใน AdMob
- [ ] **Play Games Services** (เซฟคลาวด์ — ไม่ทำก็ได้ เกมเล่นออฟไลน์ได้ครบ): Play Console → Play Games Services → Setup → คัดลอก Project ID → `pgsProjectId=…` ใน `app/android/gradle.properties`
- [ ] **สินค้าในแอป**: Play Console → Monetize → Products → In-app products → สร้าง `supporter_pack` (one-time, ไม่ใช่ subscription) ตั้งราคา · เพิ่มอีเมลตัวเองใน **License testing** เพื่อลองซื้อแบบไม่เสียเงิน

## 3. Build

```bash
scripts/build_release.sh
```
- ได้ `app/build/app/outputs/bundle/release/app-release.aab` → อัปโหลดเข้า **Internal testing** ก่อน
- สคริปต์เตือนทุกค่าที่ยังเป็นค่าทดสอบ · Mac 8 GB: ถ้าโดน kill (exit 137) ปิด Chrome แล้วรันใหม่
- [ ] **อนุญาตตัวคอมไพล์ของ Flutter ให้ครบทุก ABI (ครั้งเดียว):** บนเครื่องนี้ macOS ยังกักตัวคอมไพล์ของ ABI 32-bit ARM และ x86_64 ไว้ (ธง quarantine จากตอนดาวน์โหลด) → build ทุก ABI จะค้างเงียบ ๆ · ระหว่างนี้ใช้ `scripts/build_release.sh --arm64-only` (Play รับ — ตัดแค่มือถือ 32-bit รุ่นเก่ามาก) · ถ้าอยากได้ครบ: เปิด Terminal แล้วสั่ง `xattr -d com.apple.quarantine` กับไฟล์ `gen_snapshot` ใน `/opt/homebrew/share/flutter/bin/cache/artifacts/engine/android-arm-release/darwin-x64/` และ `android-x64-release/darwin-x64/` (เป็นการตัดสินใจเรื่องความปลอดภัยของเครื่อง Claude เลยไม่ทำให้)
- ทดสอบลงมือถือเร็ว ๆ: `scripts/build_release.sh --apk`

## 4. Play Console → App content (คำตอบที่เตรียมไว้)

| หัวข้อ | คำตอบ |
|---|---|
| Privacy policy | URL ของ `docs/privacy/index.html` หลัง host (เช่น เปิด GitHub Pages ของ repo → `/docs`) · แทน `{{DEVELOPER}}`, `{{CONTACT_EMAIL}}`, `{{DATE}}` ก่อน |
| App access | All functionality is available without special access (ไม่มีล็อกอิน) |
| Ads | **Yes, my app contains ads** (rewarded เท่านั้น) |
| Target audience | แนะนำ **ages 6–8, 9–12** (+ 13–15 ถ้าอยากให้วัยรุ่นเล่นด้วย) → เข้าโปรแกรม Families ต้องทำตาม Families policy ทั้งหมด (ทำแล้วในโค้ด: ad SDK self-certified, ไม่มี Advertising ID, child-directed, เรต G, parental gate ก่อนซื้อ) · "Appeals to children" = Yes |
| Content rating (IARC) | Category **Game** · ความรุนแรง: การ์ตูน/แฟนตาซี มอนแพ้แล้ว "ป๊อป" หายไป ไม่มีเลือด → mild fantasy violence · ไม่มีภาษาหยาบ เพศ ยาเสพติด การพนันด้วยเงินจริง · **Users interact: No** · **Shares location: No** · **Digital purchases: Yes** · ของสุ่ม (ฟักไข่/ถักของ) ได้จากของในเกมหรือดูโฆษณา **ไม่ขายด้วยเงินจริง** → ตอบว่าไม่มี loot box ที่ซื้อด้วยเงินจริง · คาดว่าได้ Everyone / PEGI 3–7 |
| News app / COVID / Government | No |
| Financial features / Health | None |

### Data safety (ตามเอกสาร AdMob ของ Google ณ 2026-10-23 — เช็กใหม่วันส่ง)

| Data type | Collected | Shared | Purpose | หมายเหตุ |
|---|---|---|---|---|
| Location → Approximate location (จาก IP) | Yes | Yes (Google AdMob) | Advertising, Fraud prevention | อัตโนมัติจาก SDK โฆษณา |
| App activity → App interactions | Yes | Yes (AdMob) | Advertising, Analytics | การกด/ดูโฆษณา |
| App info and performance → Diagnostics | Yes | Yes (AdMob) | Analytics | |
| Device or other IDs | Yes (App set ID) | Yes (AdMob) | Advertising, Fraud prevention | **ไม่มี Advertising ID** — ถอดสิทธิ์ AD_ID แล้ว (D-033) |
| App activity → Other actions (เซฟเกม) | Yes, ถ้าตั้ง PGS | No | App functionality | เก็บใน Play Games ของผู้เล่น · ไม่ตั้ง PGS = ไม่เก็บ |
| Financial info → Purchase history | Yes (แค่ "ซื้อ Supporter Pack แล้ว") | No | App functionality | การชำระเงินอยู่ที่ Google Play |

- Encrypted in transit: **Yes** · Users can request deletion: **Yes** (อีเมลในนโยบาย) · ไม่มีข้อมูลบัญชี/ชื่อ/อีเมล/รูป/ตำแหน่งละเอียด/รายชื่อ

## 5. Store listing (ร่าง — แก้ได้ตามใจ)

- **ไอคอน 512×512**: `docs/release/play_icon_512.png` · **Feature graphic 1024×500**: `docs/release/play_feature_1024x500.png` (สร้างโดย `tools/make_store_art.py`)
- [ ] **ภาพหน้าจอมือถือ 2–8 ภาพ** — ถ่ายจากมือถือจริง (ภาพ golden ใช้ฟอนต์ทดสอบ เอาไปใช้ไม่ได้) แนะนำ: หน้าเกม · ถักของ · ฟักไข่ · ห้องสมุดนกฮูก · ตู้เสื้อผ้า
- ชื่อ: **Whisker Tales** · หมวด: Game → Role Playing (หรือ Casual) · Tags: Idle, Cute

**TH — คำอธิบายสั้น (≤80):** ผจญภัยในโลกนิทานสีไม้กับลูกแมวโมจิ ถักชุด ฟักเพื่อนสัตว์ เล่นสบาย ๆ

**TH — คำอธิบายเต็ม:**
> ลูกแมวโมจิออกเดินทางในหนังสือนิทานสีไม้! ปราบยางลบขี้งอน ค้างคาวหมึก และหมาป่ากระดาษ ไปทีละหน้า
> 🧶 ถักอุปกรณ์ใหม่จากก้อนไหมพรม แล้วเลือกเก็บชิ้นที่ดีกว่า
> 🥚 ฟักไข่ได้เพื่อนสัตว์ 6 ตัวมาช่วยสู้
> 🦉 ค้นคว้าในห้องสมุดนกฮูกให้โมจิเก่งขึ้น
> 🐱 เลือกคลาส นักรบ โจร นักธนู หรือนักเวท พร้อมชุดของแต่ละคลาส
> 🌙 ปิดเกมไปโมจิก็ยังเก็บของให้
> เหมาะกับเด็ก: ไม่มีแชต ไม่ต้องสมัคร โฆษณาเป็นแบบกดดูเองเพื่อรับของเท่านั้น การซื้อต้องผ่านคำถามผู้ปกครอง และไม่ขายไหมพรม ไข่ หรือปลาทองด้วยเงินจริง

**EN — Short (≤80):** Adventure through a crayon storybook with Mochi the kitten. Knit, hatch, play!

**EN — Full:**
> Mochi the kitten sets off through a colored-pencil storybook! Pop grumpy erasers, ink bats and a giant paper wolf, page by page.
> 🧶 Knit new gear from balls of yarn and keep the better pieces
> 🥚 Hatch 6 pet friends who join the fight
> 🦉 Study in the Owl Library to make Mochi stronger
> 🐱 Pick a class — Warrior, Rogue, Archer or Mage — each with its own outfit
> 🌙 Mochi keeps collecting while the game is closed
> Made for kids: no chat, no sign-up, only optional rewarded ads, a grown-ups-only check before any purchase, and yarn, eggs and goldfish are never sold for real money.

## 6. ลองบนมือถือจริงก่อนเปิด (Claude ทดสอบไม่ได้ — เครื่องนี้ไม่มี emulator)

- [ ] ไอคอนในหน้าจอหลัก (รวมไอคอนแบบธีม Android 13+) + หน้า splash
- [ ] กดปุ่ม 📺 ทุกจุด (ฟักไข่ เร่งห้องสมุด ไหมพรม ของขวัญ เหตุการณ์) → **โฆษณาทดสอบ**ขึ้น ดูจบได้ของ · ปิดก่อนจบไม่ได้ของ · ไม่มีเน็ต = ปุ่มไม่ค้าง
- [ ] ฟังเพลง/เสียง: ดังพอดีไหม เพลงบอสสลับนุ่มไหม · ปิด 🎵/🔊 แล้วเงียบทันที · กดโฮมแล้วเพลงหยุด
- [ ] ความลื่น (60 fps) ตอนมีแมว + มอน 3 + เพื่อนสัตว์ 3 บนเครื่องระดับกลาง (T-027)
- [ ] ซื้อ Supporter Pack ด้วยบัญชี License testing → ปุ่มโฆษณาหาย · Restore หลังลบแอป
- [ ] เซฟคลาวด์ (ถ้าตั้ง PGS): เล่นเครื่อง A → เปิดเครื่อง B ได้ความคืบหน้า

## 7. ข้อที่ยังเปิดอยู่

- **ผู้เล่นใน EEA/UK**: AdMob อาจต้องใช้ฟอร์มความยินยอม (UMP) แม้จะเป็นโฆษณาแบบไม่ปรับตามบุคคล — ถ้าเปิดขายเฉพาะไทยในรอบแรกยังไม่ต้อง · ถ้าจะเปิดยุโรปบอก Claude ให้ทำ (D-033)
- แจ้งเตือน "วิจัยเสร็จ" ตอนปิดแอป = v1.1 (T-041)
- โหมดท้าทายนิทาน = กลุ่ม B (ปุ่ม 🏰 ยังเป็น "เร็ว ๆ นี้")
