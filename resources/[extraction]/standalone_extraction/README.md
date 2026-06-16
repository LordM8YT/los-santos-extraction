# standalone_extraction

Standalone extraction prototype for FiveM. No ESX, QBCore, Qbox, `ox_target`, or database is required for the current gameplay loop. The modular v2 foundation uses `ox_lib`.

## What This Resource Does

- Adds an extraction hub at LSIA.
- Lets players start private raids in their own routing buckets.
- Reads loot spots from `extraction_world`.
- Disables ambient NPCs, traffic, police spawns, garbage trucks, and random boats.
- Drops unsecured loot on death, timeout, or raid leave.
- Saves stash, cash, and progression in `data/players.json`.
- Sends inventory data to `extraction_inventory`.
- Gives new players a small starter stash through `Config.StarterKit`.

## Interactions

- Go to the `Extraction Hub` blip at the airport.
- Press `E` at `Start raid` to begin a run.
- Loot marked cache spots during the raid.
- Press `E` at an extraction zone to secure carried loot.
- Press `E` at the trader to sell secured loot.
- Press `E` at the stats point to view stash and progression.

## Commands

- `/extractstats` shows stash and progression.
- `/raidbag` shows the same panel, including carried loot when in raid.
- `/raidleave` cancels the active raid and clears carried loot.

## Files

- `fxmanifest.lua`
  Resource manifest.
- `config.lua`
  Coordinates, loot values, timers, and marker colors.
- `client/main.lua`
  Markers, HUD fallback, teleport, progress, and death handling.
- `server/main.lua`
  Raids, buckets, loot rolls, extraction, and persistence.
- `data/players.json`
  Simple file persistence without a database.

## Installation

1. Place `extraction_core`, `extraction_world`, `extraction_inventory`, `extraction_hud`, `extraction_chat`, and `standalone_extraction` in `resources`.
2. Place `ox_lib` in `resources/[overextended]`.
3. Add these to `server.cfg` in this order:
   `ensure ox_lib`
   `ensure extraction_core`
   `ensure extraction_chat`
   `ensure extraction_world`
   `ensure extraction_inventory`
   `ensure extraction_hud`
   `ensure standalone_extraction`
4. Restart the server or resources.
5. Tune coordinates and loot tables in `config.lua` and `extraction_world/shared/config.lua`.

## Future Work

- Replace prototype loot spots with custom interiors or MLOs.
- Add a trader shop, quests, weapon progression, and matchmaking.
- Build party support on top of the current private raid bucket model.
