# Damage numbers v1

Four hand-painted bitmap digit sets generated for Whisker Tales:

- `normal`: parchment cream → gold, for regular hits
- `skill`: gold → orange/coral with small sparkles, for skill and DOT hits
- `crit`: coral → gold with corner stars, for critical hits
- `hurt`: peach → coral red, for damage received by Mochi

Each folder contains `0`–`9`, `plus`, and `minus` as transparent variable-width
PNG glyphs at a shared 256 px line height. The original 6×2 atlases live in
`assets/raw/sheets/sheet_damage_numbers_<style>.png`.

`tools/sync_sprites.py` publishes 128 px mobile copies to
`app/assets/game/damage_numbers/`. Runtime composition preserves proportional
widths, slightly overlaps adjacent glyphs, and animates the complete number as
one object.

