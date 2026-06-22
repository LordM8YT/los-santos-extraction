# extraction_inventory

Raid field inventory UI resource for the extraction prototype.

## Responsibilities

- Provides a standalone NUI for raid bag views while in an active raid.
- Asks `standalone_extraction` for an authoritative snapshot before opening, so raid state cannot drift client-side.
- Routes safehouse inventory access back to the lobby loadout screen only when the server snapshot says the player is not in raid.
- Lets players drop items from the raid bag.

## Controls

- `I` opens the field inventory in raid. Outside raid it routes to the lobby loadout screen.
- `Escape` closes inventory.

## Important Files

- `client/main.lua`
  Connects the UI to events from `standalone_extraction`.
- `web/*`
  HTML, CSS, and JavaScript for the inventory panel.
