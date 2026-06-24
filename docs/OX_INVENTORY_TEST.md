# Ox Inventory LSX Bridge

LSX now targets `ox_inventory` as the inventory provider. The framework surface is `lsx_core`, not ESX, QBCore, Qbox, or ox_core gameplay.

## Runtime Stack

Start order:

```cfg
set mysql_connection_string "mysql://user:password@localhost/los_santos_extraction"
setr inventory:framework "lsx"
setr inventory:screenblur false
setr inventory:keys '["TAB"]'
setr inventory:imagepath "nui://ox_inventory/web/images"
setr inventory:dropprops true

ensure ox_lib
ensure oxmysql
ensure lsx_core
ensure ox_inventory
```

`ox_core` should stay disabled. LSX owns players, lobby flow, raid state, death/MIA, extraction, progression, and future stash/loadout rules.

## Database

For a fresh database, import:

```text
resources/[extraction]/lsx_core/sql/inventory.sql
```

The local development database has been initialized as:

```text
mysql://root@127.0.0.1/los_santos_extraction
```

Do not commit real production credentials.

## Local ox_inventory Patch

The downloaded `resources/[overextended]/ox_inventory` has a local LSX framework bridge:

- `modules/bridge/lsx/server.lua`
- `modules/bridge/lsx/client.lua`
- `modules/mysql/server.lua` has LSX table mappings for `lsx_players`, `lsx_vehicles`, and `ox_inventory`.

These files live inside the downloaded third-party dependency and are not committed as normal project resources. If ox_inventory is re-downloaded, reapply the LSX bridge before starting the server.

## Current Integration State

- `lsx_core` provides ox-style player objects, groups, statuses, licenses, and statebags.
- `ox_inventory` can load with `inventory:framework "lsx"`.
- `extraction_inventory` remains enabled only as a compatibility wrapper because `standalone_extraction` still depends on the resource. When ox is active, pressing `I` in raid opens `ox_inventory` instead of the old field inventory UI.
- Lobby stash/loadout and raid reward persistence still need to be migrated from `standalone_extraction` JSON data into ox inventory/stashes.

## Next Migration Targets

- Move starter kit insertion to ox exports.
- Move raid loot rewards to ox temporary/drop/stash flows.
- Move extraction success into ox stash persistence.
- Move death/MIA loadout loss into ox inventory/drop handling.
- Remove old NUI inventory once `standalone_extraction` no longer depends on it.
