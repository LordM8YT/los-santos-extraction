# lsx_platform

FiveM platform adapter layer for Los Santos Extraction.

The long-term goal is that gameplay resources ask `lsx_platform` for platform services instead of calling FiveM natives directly. This resource should contain FiveM-specific calls such as time/weather, entities, buckets, markers, NUI, weapons, vehicles, and animation.

## Current Services

- `exports.lsx_platform:SelectRaidTimecycle(config)`
  Server-side helper that chooses a normalized raid timecycle from weighted config.
- `lsx_platform:client:applyTimecycle`
  Client event that applies weather, clock, clock freeze, and artificial light state.
- `lsx_platform:client:resetTimecycle`
  Client event that releases raid time/weather overrides.

## Design Rule

Gameplay systems should pass data into this resource. FiveM natives should stay here whenever practical.
