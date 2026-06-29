# extraction_character

Character profile foundation for future custom operators and skins.

## Purpose

- Own future operator identity, character slots, custom model, components, and props.
- Keep character creation separate from `standalone_extraction`.
- Provide exports/events that lobby, loadout, and future character creator UI can use.

## Current State

This is a safe foundation. It applies a visible freemode model, stores the current operator in `data/characters.json`, and exposes basic current-character exports/events. The lobby can create a male or female operator now; face, clothing, components, and full creator UI can be layered on later.
