# extraction_weapons

Weapon pack adapter for Los Santos Extraction.

## Why This Exists

External FiveM weapon packs vary a lot in quality, naming, licensing and framework assumptions. This resource gives the project a stable adapter layer before importing any third-party pack.

## Current Scope

- Registers extra vanilla GTA weapons as extraction items.
- Adds weapon and ammo entries into loot tables.
- Exposes weapon definitions through server exports.

## Future Add-On Pack Flow

1. Add streamed weapon resource separately.
2. Add matching item definitions here.
3. Point `weapon` to the add-on weapon name/hash.
4. Add icon metadata and loot weights.
5. Keep `standalone_extraction` unchanged.
