# extraction_lobby

Clean safehouse lobby UI for the standalone extraction prototype.

## Purpose

This resource is a presentation layer only. Raid start, stash, selling, and inventory actions are still validated by `standalone_extraction` on the server.

## Features

- Transparent NUI with no full-screen background.
- Opens automatically after fly-in when `Config.Lobby.openUiOnJoin` is enabled.
- Opens from the hub interaction points.
- Shows player cash, level, XP, raids, best run, stash value, stash preview, and loadout preview.
- Provides buttons for deploy, stash/loadout, selling secured loot, and refresh.

## Commands

- `/extractionlobby` opens the lobby UI for quick testing.

## Browser Preview

Open `web/index.html?demo=1` in a regular browser to preview the UI with mock data outside FiveM.

## Events

- `extraction_lobby:client:open`
  Opens the lobby UI.
- `extraction_lobby:client:update`
  Receives the latest profile snapshot from `standalone_extraction`.
