# Los Santos Extraction

A standalone FiveM PvPvE extraction shooter prototype. The goal is to build a gameplay-first extraction game in Los Santos without turning it into a GTA RP server.

## Current Stack

- Lua
- FiveM natives
- ox_lib
- Custom standalone inventory/HUD/prototype persistence
- oxmysql and ox_inventory are installed locally, but intentionally not enabled yet
- EasyAdmin is installed locally and enabled as the admin menu

## Resource Layout

Custom project resources live in `resources/[extraction]`.

- `extraction_items`
  Shared item registry and tetris-ready item/container definitions.
- `extraction_core`
  Shared foundation for identifiers, logging, constants, and future routing bucket ownership.
- `extraction_admin`
  Project-specific admin helpers, including ACE-protected coordinate clipboard commands.
- `extraction_world`
  Loot crate definitions, spawned cache props, guard zones, and guard threat checks.
- `extraction_character`
  Foundation for future custom operators, character slots, models, components, and skins.
- `extraction_inventory`
  Armory-style NUI stash, loadout, raid bag, drop, and sell interface.
- `extraction_hud`
  Custom HUD, notifications, hints, raid timer, progress UI, minimap cleanup, and vanilla HUD suppression.
- `extraction_lobby`
  Cinematic safehouse lobby UI for deploy, stash/loadout access, selling, profile overview, and client HUD settings.
- `extraction_pause`
  Custom pause shell that suppresses native GTA pause/map and routes players to LSX menus.
- `extraction_loadscreen`
  Custom LSX loading screen.
- `extraction_chat`
  Default chat theme override.
- `standalone_extraction`
  Current playable raid loop, profiles, starter kit, raid vehicles, extractions, loot rewards, and JSON persistence.

## Third-Party Dependencies

These are not committed to this repo. Install Overextended resources into `resources/[overextended]` and admin tooling into `resources/[admin]`.

- `ox_lib` v3.37.2
- `oxmysql` v2.14.1
- `ox_inventory` v2.47.7
- `EasyAdmin` v7.53 pinned to `d732e54626dc362dbd1e42121c0b243eacbf24e4`

`ox_lib` and `EasyAdmin` are enabled in `server.cfg` right now. Do not enable `ox_inventory` until a supported framework bridge or custom bridge strategy is chosen. See `docs/EASYADMIN_SETUP.md` for the local admin setup.

## Server Config

The live `server.cfg` is intentionally ignored because it contains machine-specific and private values such as `sv_licenseKey`.

Use `server.example.cfg` as the safe handoff template. It currently starts:

```cfg
ensure ox_lib
ensure EasyAdmin
ensure extraction_items
ensure extraction_loadscreen
ensure extraction_core
ensure extraction_admin
ensure extraction_chat
ensure extraction_world
ensure extraction_character
ensure extraction_inventory
ensure extraction_hud
ensure extraction_lobby
ensure extraction_pause
ensure standalone_extraction
```

EasyAdmin admin menu:

```cfg
setr ea_LanguageName "en"
setr ea_defaultKey "F7"
setr ea_enableSplash false
setr ea_enableReportScreenshots false
add_ace group.admin easyadmin allow
add_ace resource.EasyAdmin command allow
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
