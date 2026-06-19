# extraction_items

Shared item registry for the standalone extraction project.

This is the first low-risk step toward a custom `extraction_inventory_v2` with tetris-style containers. The current playable raid loop still reads its legacy `Config.Items` and `Config.LootTables` from `standalone_extraction`, so this resource can be introduced without breaking live gameplay.

## Why This Exists

- Keeps item definitions out of gameplay resources long-term.
- Adds tetris inventory metadata (`width`, `height`, `stackSize`).
- Defines future container templates for stash, loadout, and raid bag.
- Creates stable exports other resources can use later.
- Leaves room for monetization entitlements without putting Tebex logic in inventory code.

## Current Exports

- `GetItem(itemName)`
- `GetItems()`
- `GetLootTable(tier)`
- `GetContainerTemplate(templateId)`
- `GetContainerTemplates()`

## Migration Plan

1. Keep `standalone_extraction` unchanged while this registry is tested.
2. Build `extraction_inventory_v2` against this registry.
3. Move loot roll logic to use `exports.extraction_items:GetLootTable(tier)`.
4. Move stash/loadout/raid bag persistence out of `standalone_extraction`.
5. Remove duplicated item definitions from `standalone_extraction` after migration.

## Monetization Note

Paid upgrades should only unlock stash tabs or stash size tiers. Do not sell raid bag size, weapons, ammo, loot, random rewards, or in-game currency.