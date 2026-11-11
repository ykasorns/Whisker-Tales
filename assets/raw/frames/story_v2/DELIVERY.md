# Adventure collectible cards v2

Six blank, portrait collectible-card frames generated for Adventure reward
choices. Live Flutter widgets place the item/talent icon, localized name,
description, rank marks, synergy mark and selection prompt over these frames.

## Variants

- Relics: `card_relic_common`, `card_relic_rare`, `card_relic_epic`
- Talents: `card_talent_claw`, `card_talent_shadow`, `card_talent_magic`

Source cards are 512×768 transparent PNGs in `cards/`. The preview sheet is
`adventure_cards_preview.png`. `tools/sync_sprites.py` publishes 320×480 mobile
copies to `app/assets/game/story/cards_v2/`.

The generated design uses three deliberate live-content zones: illustration
window, title plaque, and rules panel. The exterior is transparent so the
raised crest and rounded silhouette remain visible over the story scene.
