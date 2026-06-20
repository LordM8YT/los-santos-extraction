# extraction_inventory

Raid field inventory UI resource for the extraction prototype.

## Responsibilities

- Provides a standalone NUI for raid bag views while in an active raid.
- Routes safehouse inventory access back to the lobby loadout screen.
- Lets players drop items from the raid bag.

## Controls

- `I` opens the lobby loadout screen in safehouse and the field inventory while in raid.
- `Escape` closes inventory.

## Important Files

- `client/main.lua`
  Connects the UI to events from `standalone_extraction`.
- `web/*`
  HTML, CSS, and JavaScript for the inventory panel.
