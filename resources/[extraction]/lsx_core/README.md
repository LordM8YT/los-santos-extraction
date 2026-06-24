# lsx_core

Standalone framework core for Los Santos Extraction.

`lsx_core` is shaped like the useful parts of `ox_core` so LSX resources and future adapters can use ox-style player objects without adopting RP gameplay systems.

## Responsibilities

- Player registry keyed by source, userId, and charId.
- Identifier snapshots.
- Ox-style `GetPlayer`, `GetPlayers`, `GetPlayerFromFilter`, group, and status APIs.
- Statebag replication through `Player(source).state.lsxPlayer`.
- LSX events for player load, logout, drop, metadata, and group updates.
- No jobs, no RP death flow, no vehicle ownership, no banking/accounts.

## Server Exports

- `GetCoreObject()`
- `GetIdentifierSnapshot(source)`
- `GetPrimaryIdentifier(source)`
- `GetPlayer(source)`
- `GetPlayerFromUserId(userId)`
- `GetPlayerFromCharId(charId)`
- `GetPlayerFromFilter(filter)`
- `GetPlayers(filter)`
- `GetGroup(name)`
- `GetGroupsByType(type)`
- `SetGroupPermission(groupName, grade, permission, value)`
- `RemoveGroupPermission(groupName, grade, permission)`
- `GetGroupActivePlayers(groupName)`
- `GetGroupActivePlayersByType(groupType)`
- `SaveAllPlayers()`

## Client Exports

- `GetCoreObject()`
- `GetPlayer()`
- `GetPlayerData()`

## Import Pattern

Resources can use exports directly:

```lua
local player = exports.lsx_core:GetPlayer(source)
```

Or import the LSX object:

```lua
local LSX = require '@lsx_core.lib.init'
local player = LSX.GetPlayer(source)
```

## Ox Compatibility Strategy

This resource does not pretend to be `ox_core` and does not emit `ox:` events by default. When we integrate `ox_inventory`, use an adapter or a tiny forked bridge that talks to `lsx_core`.

If an adapter temporarily needs ox-style event aliases, set:

```cfg
setr lsx:emitOxEvents 1
```

Keep this disabled unless we are actively testing that bridge.
