# extraction_inventory

Standalone inventory UI resource for the extraction prototype.

## Responsibilities

- Provides a standalone NUI for stash and raid bag views.
- Lets players drop items from the raid bag.
- Lets players sell secured loot through the UI while standing at the trader.

## Controls

- `I` opens inventory.
- `Escape` closes inventory.

## Important Files

- `client/main.lua`
  Connects the UI to events from `standalone_extraction`.
- `web/*`
  HTML, CSS, and JavaScript for the inventory panel.
