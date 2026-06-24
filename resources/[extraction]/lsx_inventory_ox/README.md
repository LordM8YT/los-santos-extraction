# lsx_inventory_ox

Patch package for running `ox_inventory` against `lsx_core`.

`ox_inventory` loads framework integrations from its own `modules/bridge/<framework>` folder. Because downloaded third-party resources in `resources/[overextended]` are git-ignored, this resource stores the LSX bridge source and an installer script.

## Apply Patch

From the server base folder:

```powershell
powershell -ExecutionPolicy Bypass -File "resources/[extraction]/lsx_inventory_ox/install.ps1"
```

The installer:

- Copies `bridge/server/server.lua` to `resources/[overextended]/ox_inventory/modules/bridge/lsx/server.lua`.
- Copies `bridge/client/client.lua` to `resources/[overextended]/ox_inventory/modules/bridge/lsx/client.lua`.
- Patches `ox_inventory/modules/mysql/server.lua` so `inventory:framework "lsx"` uses `lsx_players`, `lsx_vehicles`, and `ox_inventory`.

Run this again after updating or re-downloading `ox_inventory`.
