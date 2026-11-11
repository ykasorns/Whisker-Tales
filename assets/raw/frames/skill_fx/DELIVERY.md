# Skill FX v1

Generated storybook/crayon animation effects for every class skill currently
defined in `design/data/skills.json`. Each skill contains eight chronological
256×256 transparent PNG frames and an animated GIF preview. Canonical 4×2
source sheets live in `assets/raw/sheets/sheet_fx_<skill>.png`.

## Direction and placement

- Target, left → right: `shield_bash`, `twin_strike`, `poison_blade`,
  `power_shot`, `fireball`
- Player-centred buffs: `iron_wall`, `war_cry`, `shadow_step`, `eagle_eye`
- Enemy-area effects: `arrow_rain`, `frost_nova`, `meteor`

The runtime never mirrors these images. Target effects begin at Mochi on the
left and travel to the nearest living monster on the right. Buffs stay centred
on Mochi. Area effects are centred over the living enemy group.

## Mobile export

Run `python3 tools/sync_sprites.py`. It publishes 192×192 optimized frames to
`app/assets/game/skill_fx/`; Flutter bundles that directory via `pubspec.yaml`.

