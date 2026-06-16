# extraction_world

World content resource for the extraction prototype.

## Responsibilities

- Spawns crate props around the city.
- Defines low, mid, and high tier loot points.
- Defines guarded high-tier zones.
- Exports loot spot data to `standalone_extraction`.

## Important Files

- `shared/config.lua`
  Loot spots, tiers, prop models, and guard zones.
- `client/main.lua`
  Spawns props and guards locally during raids, and reports guard threat state.
- `server/main.lua`
  Server exports for loot spot lookups.
