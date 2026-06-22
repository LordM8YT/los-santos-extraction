# extraction_traders

Standalone trader catalog resource for Los Santos Extraction.

## Responsibilities

- Owns trader shop definitions and prices.
- Exposes shop data through server exports.
- Keeps catalog changes out of `standalone_extraction` so gameplay state and economy config stay separate.

## Current Shop

- `quartermaster`
  Basic safehouse shop for pistol, pistol ammo and medical supplies.

## Important Rule

This resource does not mutate player data. Purchases are validated and applied by `standalone_extraction` server-side so cash, raid state and stash updates remain authoritative.
