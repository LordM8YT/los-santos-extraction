# Los Santos Extraction

A standalone FiveM PvPvE extraction shooter prototype. The goal is to build a gameplay-first extraction game in Los Santos without turning it into a GTA RP server.

## Current Stack

- Lua
- FiveM natives
- ox_lib
- Custom standalone inventory/HUD/prototype persistence
- oxmysql and ox_inventory are installed locally, but intentionally not enabled yet

## Resource Layout

Custom project resources live in `resources/[extraction]`.

- `extraction_core`
  Shared foundation for identifiers, logging, constants, and future routing bucket ownership.
- `extraction_world`
  Loot crate definitions, spawned cache props, guard zones, and guard threat checks.
- `extraction_inventory`
  Custom NUI stash, loadout, raid bag, drop, and sell interface.
- `extraction_hud`
  Custom HUD, notifications, hints, raid timer, progress UI, minimap cleanup, and vanilla HUD suppression.
- `extraction_chat`
  Default chat theme override.
- `standalone_extraction`
  Current playable raid loop, profiles, starter kit, raid vehicles, extractions, loot rewards, and JSON persistence.

## Third-Party Dependencies

These are not committed to this repo. Install them into `resources/[overextended]`.

- `ox_lib` v3.37.2
- `oxmysql` v2.14.1
- `ox_inventory` v2.47.7

Only `ox_lib` is enabled in `server.cfg` right now. Do not enable `ox_inventory` until a supported framework bridge or custom bridge strategy is chosen.

## Server Config

The live `server.cfg` is intentionally ignored because it contains machine-specific and private values such as `sv_licenseKey`.

Use `server.example.cfg` as the safe handoff template. It currently starts:

```cfg
ensure ox_lib
ensure extraction_core
ensure extraction_chat
ensure extraction_world
ensure extraction_inventory
ensure extraction_hud
ensure standalone_extraction
```

## Development Rules

- Keep each feature in its own resource.
- Keep gameplay values in config files.
- Keep client, server, and shared logic separated.
- Avoid ESX/QBCore unless the project explicitly changes direction.
- Do not rename item keys without a migration for saved player data.
- Do not commit `standalone_extraction/data/players.json`.

## Handoff Notes

Start with `resources/[extraction]/DEVELOPER_HANDOFF.md` for current architecture and planned systems.
