# Contributing

This project is being built in small, runnable milestones. Please keep changes focused and easy to review.

## Before Changing Code

- Read `README.md`.
- Read `resources/[extraction]/DEVELOPER_HANDOFF.md`.
- Start the server once and confirm the current baseline works.

## Code Style

- Use clear English names for resources, events, variables, config keys, and UI text.
- Put feature values in config files instead of hardcoding them in logic.
- Keep server authority on gameplay-critical actions such as raid start, loot rewards, stash changes, selling, and extraction.
- Prefer small resources over large mixed-purpose scripts.
- Avoid adding dependencies unless there is a clear reason.

## Testing Checklist

- Resource starts without console errors.
- Player spawns at the hub.
- Starting a raid works.
- Loot crates spawn and can be searched.
- Guarded high-tier loot blocks interaction while guards are active.
- Extraction returns the player to the hub and secures loot.
- Inventory opens with `I` and does not show a full-screen background.
- HUD does not show vanilla GTA clutter.

## Dependency Notes

`ox_lib` is active. `oxmysql` and `ox_inventory` are local dependencies but not part of the active runtime yet.
