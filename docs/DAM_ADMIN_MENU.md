# DAM Admin Menu Setup

DAM is installed as a third-party admin tool, not as part of the gameplay resources.

## Install Location

Clone DAM into:

```text
resources/[admin]/dam
```

Pinned commit:

```text
abc0938dcc7a24f049d02be081d8d372885da186
```

## Local Project Patches

Apply these project-specific changes after installing DAM:

- Set `enable_permissions = true` in `custom/cfg.lua`.
- Replace the default `exports.rig` revive/kill hooks in `custom/hooks.lua` with standalone client events.
- Add standalone revive/kill client event handlers in `src/client/actions/user.lua`.

These changes keep the menu framework-free and compatible with the extraction prototype.

## Server Config

DAM requires `oxmysql` and a valid MySQL connection before it should be enabled.

```cfg
set mysql_connection_string "mysql://user:password@localhost/extraction"
setr dam:debug false
setr dam:language en
add_ace group.admin dam.admin allow
add_ace group.admin dam.dev allow
ensure oxmysql
ensure dam
```

Open the menu with `/dam` or the default F7 keybind.
