# Ox Inventory Test Plan

This project can test `ox_inventory` through `ox_core` without replacing the current extraction inventory yet.

`ox_core` is not a gameplay framework for LSX. It is only installed as the lightest available bridge for testing `ox_inventory` without ESX/QBCore.

## Installed Local Dependencies

- `resources/[overextended]/ox_lib`
- `resources/[overextended]/oxmysql`
- `resources/[overextended]/ox_core` pinned to `v1.5.14`
- `resources/[overextended]/ox_inventory` pinned to `v2.47.7`

`ox_inventory` has a local LSX visual theme at `web/build/assets/lsx-theme.css`.
LSX loot icons have been copied into `ox_inventory/web/images`.
LSX loot items have been added to `ox_inventory/data/items.lua`.

## Required Before Enabling

1. Create a MySQL database for the server.
2. Import `resources/[overextended]/ox_core/sql/install.sql`.
3. Set a real `mysql_connection_string` in local `server.cfg`.
4. Enable the resources in this order:

```cfg
ensure oxmysql
ensure ox_core
setr inventory:framework "ox"
setr inventory:screenblur false
setr inventory:keys '["TAB"]'
setr ox:characterSelect 0
setr ox:characterSlots 1
setr ox:deathSystem 0
setr ox:hospitalBlips 0
setr ox:debug 0
setr ox:spawnLocation "[-1040.31, -2732.27, 20.17, 330.0]"
ensure ox_inventory
```

## RP Systems Disabled For LSX

Keep these ox systems off when testing:

- `ox:characterSelect 0` so LSX keeps control of lobby, operator selection, and raid entry.
- `ox:deathSystem 0` so LSX owns death, MIA, loadout loss, death drops, and extraction results.
- `ox:hospitalBlips 0` so no hospital/RP markers appear on the map.
- `ox:spawnLocation` points at the LSX safehouse fallback, not an RP spawn.

Do not build gameplay against ox accounts, groups, vehicle ownership, jobs, hospitals, or character flows. If the project commits to `ox_inventory` long term, the clean production path is a small LSX inventory adapter or a maintained `ox_inventory` fork that removes the remaining ox_core assumptions.

## Migration Rule

Keep `extraction_inventory` enabled during the first test. Do not wire raid death, extraction rewards, stash saving, or trader buys to `ox_inventory` until:

- `ox_core` starts without database errors.
- A player can spawn without fighting the LSX lobby flow.
- `ox_inventory` opens and shows items.
- LSX loot icons render correctly.
- Weapons and ammo can be added through ox exports.

## Known Limitation

The current ox UI is slot-based, not real tetris/grid-size based. The LSX theme makes it visually closer to an extraction inventory, but true 2x3 / 1x2 item footprint behavior requires forking or rebuilding the ox React UI.
