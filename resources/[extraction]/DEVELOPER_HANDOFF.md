# Extraction Server Developer Handoff

This folder contains a standalone FiveM extraction prototype. The current goal is to keep the core gameplay framework-free where possible while integrating selected Overextended tools where they give clear long-term value.

## Resource Overview

- `extraction_items`
  Shared item registry with tetris metadata and future container templates.
- `lsx_core`
  Standalone LSX framework core. Provides ox-style player objects, identifiers, groups, statuses, licenses, statebag replication, and compatibility events without jobs, RP death, banking, hospitals, or vehicle ownership.
- `extraction_weapons`
  Weapon-pack adapter. Registers lootable weapon/ammo items and exposes weapon loot tables without coupling streamed weapon packs into the raid loop.
- `extraction_traders`
  Standalone trader catalog. Start before `standalone_extraction`; purchases are still validated and applied by `standalone_extraction`.
- `extraction_core`
  Modular v2 foundation: shared config, constants, logging, player identifiers, and routing bucket allocation.
- `extraction_admin`
  Project-specific admin helpers. Current commands: `/copycoords`, `/coords`, `/coords vec4`, and `/coords table`. Access is gated by the same `easyadmin` ACE permission as EasyAdmin.
- `standalone_extraction`
  Core raid loop, player profiles, stash persistence, extraction routes, raid vehicles, starter kit, and routing buckets.
- `extraction_world`
  Loot crate props, loot spot definitions, high-tier guard zones, and guard threat checks.
- `extraction_character`
  Foundation for future custom operators, character slots, models, components, props, and skins.
- `extraction_inventory`
  Legacy compatibility wrapper. With `inventory:framework "lsx"` and `ox_inventory` running, raid inventory opens ox instead of the old NUI.
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
- `ox_core`
  Installed Overextended core framework for reference only. Do not use it for LSX gameplay or inventory unless an isolated future test explicitly needs it.
- `ox_inventory`
  Installed Overextended inventory. A local LSX visual theme, LSX loot item definitions, and LSX framework bridge have been applied. It runs through `inventory:framework "lsx"` and depends on `oxmysql` plus `lsx_core`, not ox_core.

Admin tooling is kept outside this folder in `resources/[admin]`:

- `EasyAdmin`
  Standalone admin menu. It is enabled in `server.cfg`, uses ACE permissions, and opens with `/easyadmin` or F7. See `docs/EASYADMIN_SETUP.md`.

## Current Design

- Raids are private instances per player using routing buckets.
- `extraction_core` now owns the future shared bucket allocator, but the current prototype still uses its existing raid flow until migrated.
- `lsx_core` is the new framework layer. Existing resources should migrate to its exports/events gradually instead of calling third-party framework APIs directly.
- Player data is stored in `standalone_extraction/data/players.json`.
- `ox_inventory` is the target inventory provider. The old `extraction_inventory` resource remains only as a compatibility wrapper until `standalone_extraction` is migrated off its legacy snapshot events.
- Weapon and ammo loot can be extended through `extraction_weapons`. The current implementation uses vanilla GTA weapons first, so a third-party weapon pack can be added later by mapping add-on weapon names/hashes in one adapter resource.
- Quest rewards are currently handled in `standalone_extraction` as a small profile-backed prototype. Claimed quest IDs are stored on the player profile in `questClaims`.
- Trader catalog data lives in `extraction_traders`; player cash/stash mutations stay server-authoritative in `standalone_extraction`.
- Safehouse inventory is integrated into `extraction_lobby`. `extraction_inventory` is the separate field inventory used while in raid.
- Initial join uses lobby staging: the player ped is hidden/frozen behind the lobby UI and should not become playable until raid start.
- Lobby settings are currently client-side KVP preferences. `extraction_lobby` sends updates through `extraction_hud:client:setSettings`.
- Extraction points should remain believable city exits such as tunnels, channels, highway ramps, ferry/boat ramps, rail exits, and service gates. Do not place extracts directly beside loot clusters unless the encounter is intentionally balanced around that risk.
- `ox_lib`, `oxmysql`, and `ox_inventory` are enabled locally. `ox_inventory` must run through the LSX bridge with `inventory:framework "lsx"`.
- `ox_core` RP-facing systems must stay disabled. Do not use ox character selection, death, hospital blips, jobs, accounts, or vehicle ownership for LSX gameplay.
- EasyAdmin is downloaded into `resources/[admin]/EasyAdmin` and enabled as the current admin menu.
- User-facing text and documentation should stay in English for easier external collaboration.
- Internal item keys should remain stable because saved player data references them.

## Planned Systems

- Expanded trader shop with armor, backpacks, meds, price balancing, reputation and unlock tiers.
- Lore-friendly third-party weapon pack selection, icon pass, recoil/damage balancing, and guarded weapon crate tuning.
- `extraction_player` resource for profile/progression persistence.
- Character creator UI and persistence on top of `extraction_character`.
- Quest/task system with cash, XP, and item rewards.
- Party system with shared raid buckets and party leader flow.
- Cleaner HUD pass once the gameplay loop is more complete.
- Finish the ox inventory migration: starter kit, raid loot, extraction rewards, death drops, MIA deletion, stash/loadout, and lobby inventory.

## Notes For Future Developers

- Avoid hard dependencies in `standalone_extraction` unless the project intentionally moves away from standalone mode.
- Prefer provider/adapters for third-party systems so the core raid loop stays portable.
- Keep player-facing strings in config where possible.
- Do not rename item keys without a migration for `data/players.json`.
- `ox_inventory` should run through the local LSX bridge, not ESX/QBCore/ox_core. Import `resources/[extraction]/lsx_core/sql/inventory.sql`, set `mysql_connection_string`, then start `oxmysql`, `lsx_core`, and `ox_inventory`.
- Do not wire LSX features to ox jobs, groups, hospitals, character selection, vehicle ownership, or account systems.
- New gameplay resources should depend on `lsx_core` for player data and only depend on ox resources through explicit adapter resources.
