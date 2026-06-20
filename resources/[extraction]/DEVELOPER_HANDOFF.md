# Extraction Server Developer Handoff

This folder contains a standalone FiveM extraction prototype. The current goal is to keep the core gameplay framework-free where possible while integrating selected Overextended tools where they give clear long-term value.

## Resource Overview

- `extraction_items`
  Shared item registry with tetris metadata and future container templates.
- `extraction_core`
  Modular v2 foundation: shared config, constants, logging, player identifiers, and routing bucket allocation.
- `standalone_extraction`
  Core raid loop, player profiles, stash persistence, extraction routes, raid vehicles, starter kit, and routing buckets.
- `extraction_world`
  Loot crate props, loot spot definitions, high-tier guard zones, and guard threat checks.
- `extraction_character`
  Foundation for future custom operators, character slots, models, components, props, and skins.
- `extraction_inventory`
  Armory-style standalone NUI for stash, loadout, raid bag, item dropping, and selling secured loot.
- `extraction_hud`
  Custom extraction HUD, notifications, hints, progress display, raid timer, client-side HUD/minimap preferences, and vanilla HUD suppression.
- `extraction_lobby`
  Cinematic safehouse lobby NUI for deploy, stash/loadout access, selling, profile overview, and client HUD settings.
- `extraction_pause`
  Custom pause shell that suppresses native GTA pause/map and exposes LSX menu actions.
- `extraction_loadscreen`
  Custom LSX loading screen.
- `extraction_chat`
  Theme override for the default FiveM chat resource.

Third-party dependencies are kept outside this folder in `resources/[overextended]`:

- `ox_lib`
  Installed Overextended utility library. Enabled before `extraction_core` in `server.cfg`.
- `oxmysql`
  Installed MySQL bridge. Requires `mysql_connection_string` before enabling.
- `ox_inventory`
  Installed Overextended inventory. Requires `oxmysql`, `ox_lib`, and a supported bridge before enabling.

## Current Design

- Raids are private instances per player using routing buckets.
- `extraction_core` now owns the future shared bucket allocator, but the current prototype still uses its existing raid flow until migrated.
- Player data is stored in `standalone_extraction/data/players.json`.
- Inventory is custom and standalone for now. `extraction_items` is the new shared registry for the future tetris inventory migration.
- Safehouse inventory is integrated into `extraction_lobby`. `extraction_inventory` is the separate field inventory used while in raid.
- Initial join uses lobby staging: the player ped is hidden/frozen behind the lobby UI and should not become playable until raid start.
- Lobby settings are currently client-side KVP preferences. `extraction_lobby` sends updates through `extraction_hud:client:setSettings`.
- Extraction points should remain believable city exits such as tunnels, channels, highway ramps, ferry/boat ramps, rail exits, and service gates. Do not place extracts directly beside loot clusters unless the encounter is intentionally balanced around that risk.
- `ox_lib` is enabled. `oxmysql` and `ox_inventory` are downloaded into `resources/[overextended]` but intentionally not auto-started yet.
- User-facing text and documentation should stay in English for easier external collaboration.
- Internal item keys should remain stable because saved player data references them.

## Planned Systems

- Trader shop for weapons, ammo, armor, and meds.
- `extraction_player` resource for profile/progression persistence.
- Character creator UI and persistence on top of `extraction_character`.
- Quest/task system with cash, XP, and item rewards.
- Party system with shared raid buckets and party leader flow.
- Cleaner HUD pass once the gameplay loop is more complete.
- Adapter layer for `ox_lib`, `oxmysql`, and/or `ox_inventory` after the database and inventory provider strategy is locked.

## Notes For Future Developers

- Avoid hard dependencies in `standalone_extraction` unless the project intentionally moves away from standalone mode.
- Prefer provider/adapters for third-party systems so the core raid loop stays portable.
- Keep player-facing strings in config where possible.
- Do not rename item keys without a migration for `data/players.json`.
- Do not enable `ox_inventory` without choosing a bridge. This release supports `ox_core`, ESX, Qbox, and ND out of the box, but this project currently avoids ESX/QBCore.
