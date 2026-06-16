# extraction_core

Foundation resource for the modular PvPvE extraction framework.

This resource intentionally does not own the full gameplay loop yet. It provides stable primitives that future resources can share without creating circular dependencies or duplicated logic.

## Responsibilities

- Shared project config and constants.
- Server logging helpers.
- Player identifier snapshots.
- Routing bucket allocation for raid instances.
- Lightweight status callback/export for diagnostics.

## Why This Exists

The prototype resource `standalone_extraction` currently owns several unrelated systems. `extraction_core` starts the migration toward smaller production resources without breaking the playable prototype.

Future resources should depend on `extraction_core` for common primitives instead of re-implementing identifiers, bucket allocation, or raid state names.

## Exports

Server:

- `GetStatus()`
- `GetIdentifierSnapshot(source)`
- `GetPrimaryIdentifier(source)`
- `AllocateBucket(key)`
- `ReleaseBucket(key)`
- `GetBucket(key)`
- `SetPlayerBucket(source, bucket)`
- `MovePlayerToLobby(source)`
- `GetBucketStats()`

Client:

- `GetSharedConfig()`
- `GetConstants()`

## Next Milestone

Create `extraction_player` and move profile/progression persistence out of `standalone_extraction`, using `oxmysql` once database configuration is ready.
