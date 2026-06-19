# Item Icons

This folder contains standalone item icons used by `extraction_items`.

Use ox_inventory-compatible filenames where practical, but copy the assets into this resource instead of depending on `ox_inventory` at runtime.

Current conventions:

- `image` fields in `shared/items.lua` are filenames relative to this folder.
- PNG files can be copied from local ox_inventory assets when matching icons exist.
- SVG files are lightweight project placeholders for custom extraction loot.
- Future inventory/trader/lobby UIs should resolve icons through this resource, not through ox paths directly.